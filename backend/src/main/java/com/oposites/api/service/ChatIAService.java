package com.oposites.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.oposites.api.exception.AppException;
import com.oposites.api.model.chat.ConversacionContexto;
import com.oposites.api.model.chat.TemaDebilInfo;
import com.oposites.api.model.dto.request.CrearConversacionRequest;
import com.oposites.api.model.dto.request.EnviarMensajeRequest;
import com.oposites.api.model.dto.response.ConversacionResponse;
import com.oposites.api.model.dto.response.EnviarMensajeResponse;
import com.oposites.api.model.dto.response.MensajeResponse;
import com.oposites.api.model.entity.ChatConversacion;
import com.oposites.api.model.entity.ChatMensaje;
import com.oposites.api.model.entity.Documento;
import com.oposites.api.model.entity.MaterialGenerado;
import com.oposites.api.model.entity.RamaOposicion;
import com.oposites.api.model.entity.Tema;
import com.oposites.api.model.entity.Usuario;
import com.oposites.api.model.enums.ChatModo;
import com.oposites.api.model.enums.EstadoEditorialNoticia;
import com.oposites.api.model.enums.TipoMaterial;
import com.oposites.api.repository.ChatConversacionRepository;
import com.oposites.api.repository.ChatMensajeRepository;
import com.oposites.api.repository.DocumentoRepository;
import com.oposites.api.repository.MaterialGeneradoRepository;
import com.oposites.api.repository.NoticiaConvocatoriaRepository;
import com.oposites.api.repository.ProgresoUsuarioRepository;
import com.oposites.api.repository.RamaOposicionRepository;
import com.oposites.api.repository.TemaRepository;
import com.oposites.api.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChatIAService {

    // Máximo de mensajes cargados desde BD (hard limit en la query)
    private static final int MAX_HISTORY_MESSAGES = 20;
    // Presupuesto de caracteres del historial enviado al LLM.
    // Groq/Llama 3.3-70b: 32k tokens ≈ 128k chars. Reservamos ~12k para historial,
    // dejando margen al system prompt (~4k) y a la respuesta esperada.
    private static final int MAX_HISTORY_CHARS = 12_000;
    // Máximo de caracteres permitidos en un único mensaje del usuario
    private static final int MAX_USER_MESSAGE_CHARS = 2_000;
    // Número de temas débiles incluidos en el system prompt
    private static final int TOP_TEMAS_DEBILES = 3;

    private static final int MAX_CONVOCATORIAS = 5;

    // 1.4 — Límite de caracteres del texto extraído cuando no hay RESUMEN disponible (~750 tokens)
    private static final int MAX_CHARS_CONTEXTO_DOC = 3_000;

    private final AiProviderChain aiProviderChain;
    private final ChatConversacionRepository conversacionRepository;
    private final ChatMensajeRepository mensajeRepository;
    private final UsuarioRepository usuarioRepository;
    private final RamaOposicionRepository ramaRepository;
    private final TemaRepository temaRepository;
    private final ProgresoUsuarioRepository progresoRepository;
    private final NoticiaConvocatoriaRepository noticiaRepository;
    private final DocumentoRepository documentoRepository;
    private final MaterialGeneradoRepository materialGeneradoRepository;
    private final ObjectMapper objectMapper;

    // ─── Endpoints USER ───────────────────────────────────────────────────────

    public List<ConversacionResponse> listarConversaciones(String email) {
        Long usuarioId = findUsuario(email).getId();
        return conversacionRepository.findByUsuarioIdOrderByCreatedAtDesc(usuarioId)
                .stream()
                .map(c -> toConversacionResponse(c, leerContexto(c)))
                .toList();
    }

    @Transactional
    public ConversacionResponse crearConversacion(String email, CrearConversacionRequest request) {
        Usuario usuario = findUsuario(email);
        RamaOposicion rama = resolveRama(usuario.getRamaPrincipalId());

        // 1.4 — Resolver documento anclado (opcional, con ownership check)
        Documento documento = null;
        if (request != null && request.getDocumentoId() != null) {
            documento = documentoRepository.findByIdAndUsuarioId(request.getDocumentoId(), usuario.getId())
                    .orElseThrow(() -> new AppException("Documento no encontrado.", HttpStatus.NOT_FOUND));
        }

        // 1.6 — Modo de conversación (GENERAL por defecto)
        ChatModo modo = (request != null && request.getModo() != null) ? request.getModo() : ChatModo.GENERAL;

        ConversacionContexto contexto = buildContexto(usuario, rama, documento, modo);

        ChatConversacion conversacion = ChatConversacion.builder()
                .usuario(usuario)
                .rama(rama)
                .documento(documento)
                .modo(modo)
                .contexto(escribirContexto(contexto))
                .build();

        return toConversacionResponse(conversacionRepository.save(conversacion), contexto);
    }

    public List<MensajeResponse> listarMensajes(Long conversacionId, String email) {
        findByIdAndOwner(conversacionId, findUsuario(email).getId()); // ownership check
        return mensajeRepository.findByConversacionIdOrderByCreatedAtAsc(conversacionId)
                .stream()
                .map(this::toMensajeResponse)
                .toList();
    }

    @Transactional
    public EnviarMensajeResponse enviarMensaje(Long conversacionId, String email, EnviarMensajeRequest request) {
        Usuario usuario = findUsuario(email);
        ChatConversacion conversacion = findByIdAndOwner(conversacionId, usuario.getId());

        // 0. Guard: mensaje demasiado largo
        if (request.getMensaje() != null && request.getMensaje().length() > MAX_USER_MESSAGE_CHARS) {
            throw new AppException(
                    "El mensaje es demasiado largo. El máximo permitido es " + MAX_USER_MESSAGE_CHARS + " caracteres.",
                    HttpStatus.BAD_REQUEST);
        }

        // 1. Persiste el mensaje del usuario
        mensajeRepository.save(ChatMensaje.builder()
                .conversacion(conversacion)
                .esIa(false)
                .mensaje(request.getMensaje())
                .build());

        // 2. Recupera la ventana de historial (DESC → revertir a ASC para el LLM) y aplica límite de chars
        List<ChatMensaje> historialDesc = mensajeRepository
                .findTop20ByConversacionIdOrderByCreatedAtDesc(conversacionId);
        List<ChatMensaje> historialAsc = new ArrayList<>(historialDesc);
        Collections.reverse(historialAsc);
        historialAsc = truncarHistorialPorChars(historialAsc);

        // 3. Construye los mensajes para el LLM
        // 1.5 — Regeneración de contexto: se recalcula en cada mensaje para reflejar
        // el progreso real del usuario. 1.4 — incluye contenido documental si la conversación está anclada.
        ConversacionContexto contexto = buildContexto(usuario,
                resolveRama(usuario.getRamaPrincipalId()),
                conversacion.getDocumento(),
                conversacion.getModo());
        List<Message> llmMessages = new ArrayList<>();
        llmMessages.add(new SystemMessage(buildSystemPrompt(contexto)));

        for (ChatMensaje m : historialAsc) {
            llmMessages.add(m.isEsIa()
                    ? new AssistantMessage(m.getMensaje())
                    : new UserMessage(m.getMensaje()));
        }

        // 4. Llama al LLM con fallback automático (Groq → Cerebras → Gemini)
        String respuestaTexto;
        try {
            respuestaTexto = aiProviderChain.call(llmMessages);
        } catch (Exception e) {
            if (esErrorRateLimit(e)) {
                throw new AppException(
                        "La IA está ocupada. Esperá unos segundos y volvé a intentarlo.",
                        HttpStatus.TOO_MANY_REQUESTS);
            }
            throw new AppException(
                    "El servicio de IA no está disponible en este momento. Inténtalo de nuevo.",
                    HttpStatus.SERVICE_UNAVAILABLE);
        }

        // 5. Persiste la respuesta de IA
        ChatMensaje respuesta = mensajeRepository.save(ChatMensaje.builder()
                .conversacion(conversacion)
                .esIa(true)
                .mensaje(respuestaTexto)
                .build());

        return EnviarMensajeResponse.builder()
                .id(respuesta.getId())
                .mensaje(respuesta.getMensaje())
                .createdAt(respuesta.getCreatedAt())
                .build();
    }

    @Transactional
    public ConversacionResponse cambiarModo(Long conversacionId, String email, ChatModo modo) {
        Usuario usuario = findUsuario(email);
        ChatConversacion conversacion = findByIdAndOwner(conversacionId, usuario.getId());

        conversacion.setModo(modo);

        // Reconstruir contexto con el nuevo modo (para que el JSONB quede actualizado en lista)
        ConversacionContexto contexto = buildContexto(usuario,
                resolveRama(usuario.getRamaPrincipalId()),
                conversacion.getDocumento(),
                modo);
        conversacion.setContexto(escribirContexto(contexto));

        return toConversacionResponse(conversacionRepository.save(conversacion), contexto);
    }

    @Transactional
    public void eliminarConversacion(Long conversacionId, String email) {
        ChatConversacion conversacion = findByIdAndOwner(conversacionId, findUsuario(email).getId());
        conversacionRepository.delete(conversacion);
    }

    // ─── Construcción del contexto y system prompt ────────────────────────────

    private ConversacionContexto buildContexto(Usuario usuario, RamaOposicion rama, Documento documento, ChatModo modo) {
        String nombreRama = rama != null ? rama.getNombre() : null;
        String fechaExamen = usuario.getFechaExamenObjetivo() != null
                ? usuario.getFechaExamenObjetivo().toString()
                : null;

        // Días hasta el examen (calculado en vivo para que sea siempre exacto)
        Integer diasHastaExamen = null;
        if (usuario.getFechaExamenObjetivo() != null) {
            long dias = ChronoUnit.DAYS.between(LocalDate.now(), usuario.getFechaExamenObjetivo());
            diasHastaExamen = dias >= 0 ? (int) dias : null; // null si el examen ya pasó
        }

        // 1.1 — Métricas globales de rendimiento
        long total = progresoRepository.countByUsuarioId(usuario.getId());
        long correctas = progresoRepository.countByUsuarioIdAndCorrectoTrue(usuario.getId());
        double porcentajeGlobal = total > 0
                ? Math.round((correctas * 100.0 / total) * 10.0) / 10.0
                : 0.0;

        LocalDateTime inicioSemana = LocalDate.now().with(DayOfWeek.MONDAY).atStartOfDay();
        int respuestasEstaSemana = (int) progresoRepository
                .countByUsuarioIdAndFechaRespuestaAfter(usuario.getId(), inicioSemana);

        // 1.1 — Días activos esta semana
        int diasActivosEstaSemana = progresoRepository
                .countDiasActivosDesde(usuario.getId(), inicioSemana).intValue();

        // 1.1 — % de acierto esta semana (solo si hay respuestas)
        Double porcentajeAciertoEstaSemana = null;
        if (respuestasEstaSemana > 0) {
            long correctasEstaSemana = progresoRepository
                    .countByUsuarioIdAndCorrectoTrueAndFechaRespuestaAfter(usuario.getId(), inicioSemana);
            porcentajeAciertoEstaSemana =
                    Math.round(correctasEstaSemana * 100.0 / respuestasEstaSemana * 10.0) / 10.0;
        }

        // 1.1 — Días desde la última actividad
        Integer diasDesdeUltimaActividad = progresoRepository
                .findUltimaActividad(usuario.getId())
                .map(ultima -> (int) ChronoUnit.DAYS.between(ultima.toLocalDate(), LocalDate.now()))
                .orElse(null);

        // Temas débiles: nombre (para compat. lista) + detalle con % (para system prompt)
        List<String> temasDebiles = List.of();
        List<TemaDebilInfo> temasDebilesDetalle = List.of();

        if (usuario.getRamaPrincipalId() != null && total > 0) {
            List<Long> temaIds = progresoRepository.findTemaIdsOrdenadosPorDebilidad(
                    usuario.getId(), usuario.getRamaPrincipalId(),
                    PageRequest.of(0, TOP_TEMAS_DEBILES));

            if (!temaIds.isEmpty()) {
                // % de acierto por tema para los IDs seleccionados
                List<Object[]> stats = progresoRepository.findEstadisticasPorTema(
                        usuario.getId(), usuario.getRamaPrincipalId());
                Map<Long, Double> pctPorTema = stats.stream()
                        .collect(Collectors.toMap(
                                row -> ((Number) row[0]).longValue(),
                                row -> Math.round(((Number) row[2]).longValue() * 100.0
                                        / ((Number) row[1]).longValue() * 10.0) / 10.0
                        ));

                // Preservar el orden de debilidad que da la query
                Map<Long, Tema> temasPorId = temaRepository.findAllById(temaIds).stream()
                        .collect(Collectors.toMap(Tema::getId, t -> t));

                temasDebilesDetalle = temaIds.stream()
                        .filter(temasPorId::containsKey)
                        .map(id -> TemaDebilInfo.builder()
                                .nombre(temasPorId.get(id).getNombre())
                                .porcentajeAcierto(pctPorTema.getOrDefault(id, 0.0))
                                .build())
                        .toList();

                temasDebiles = temasDebilesDetalle.stream()
                        .map(TemaDebilInfo::getNombre)
                        .toList();
            }
        }

        // Convocatorias y noticias recientes
        List<String> convocatorias;
        Pageable top5 = PageRequest.of(0, MAX_CONVOCATORIAS);
        if (usuario.getRamaPrincipalId() != null) {
            convocatorias = noticiaRepository
                    .findFiltered(usuario.getRamaPrincipalId(), null, EstadoEditorialNoticia.PUBLICADA, null, top5)
                    .getContent()
                    .stream()
                    .map(n -> "[%s] %s: %s".formatted(
                            n.getTipo().name(),
                            n.getTitulo(),
                            n.getContenido().length() > 300
                                    ? n.getContenido().substring(0, 300) + "..."
                                    : n.getContenido()))
                    .toList();
        } else {
            convocatorias = noticiaRepository
                    .findGlobalFiltered(null, EstadoEditorialNoticia.PUBLICADA, null, top5)
                    .getContent()
                    .stream()
                    .map(n -> "[%s] %s: %s".formatted(
                            n.getTipo().name(),
                            n.getTitulo(),
                            n.getContenido().length() > 300
                                    ? n.getContenido().substring(0, 300) + "..."
                                    : n.getContenido()))
                    .toList();
        }

        // 1.4 — Contexto documental: resuelto en runtime, no persiste en JSONB
        String nombreDocumento = null;
        String contenidoDocumental = null;
        boolean esExtracto = false;
        if (documento != null) {
            nombreDocumento = documento.getNombre();
            contenidoDocumental = resolverContenidoDocumental(documento);
            esExtracto = contenidoDocumental != null
                    && documento.getTextoExtraido() != null
                    && contenidoDocumental.equals(documento.getTextoExtraido().length() > MAX_CHARS_CONTEXTO_DOC
                            ? documento.getTextoExtraido().substring(0, MAX_CHARS_CONTEXTO_DOC)
                            : documento.getTextoExtraido());
        }

        ConversacionContexto ctx = ConversacionContexto.builder()
                .nombreRama(nombreRama)
                .fechaExamen(fechaExamen)
                .diasHastaExamen(diasHastaExamen)
                .temasDebiles(temasDebiles)
                .temasDebilesDetalle(temasDebilesDetalle)
                .totalRespuestas((int) total)
                .porcentajeAciertoGlobal(porcentajeGlobal)
                .respuestasEstaSemana(respuestasEstaSemana)
                .diasActivosEstaSemana(diasActivosEstaSemana)
                .porcentajeAciertoEstaSemana(porcentajeAciertoEstaSemana)
                .diasDesdeUltimaActividad(diasDesdeUltimaActividad)
                .convocatorias(convocatorias)
                .nombreDocumento(nombreDocumento)
                .build();

        // Campos transient: no llegan al JSONB gracias a @JsonIgnore
        ctx.setContenidoDocumental(contenidoDocumental);
        ctx.setContenidoDocumentalEsExtracto(esExtracto);
        ctx.setModo(modo != null ? modo : ChatModo.GENERAL);

        return ctx;
    }

    /**
     * Resuelve el contenido que se inyectará como contexto documental en el system prompt.
     * Prioridad: RESUMEN generado → texto extraído truncado a MAX_CHARS_CONTEXTO_DOC.
     */
    private String resolverContenidoDocumental(Documento documento) {
        // 1. Intentar RESUMEN generado (más condensado, mejor para el LLM)
        try {
            var resumenOpt = materialGeneradoRepository
                    .findTopByDocumentoIdAndTipoOrderByCreadoEnDesc(documento.getId(), TipoMaterial.RESUMEN);
            if (resumenOpt.isPresent()) {
                com.fasterxml.jackson.databind.JsonNode nodo = objectMapper.readTree(resumenOpt.get().getContenido());
                String texto = nodo.path("texto").asText("");
                if (!texto.isBlank()) return texto;
            }
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            log.warn("Error al parsear RESUMEN del documento {}: {}", documento.getId(), e.getMessage());
        }

        // 2. Fallback: texto extraído truncado
        String raw = documento.getTextoExtraido();
        if (raw == null || raw.isBlank()) return null;
        return raw.length() > MAX_CHARS_CONTEXTO_DOC
                ? raw.substring(0, MAX_CHARS_CONTEXTO_DOC)
                : raw;
    }

    /**
     * Construye el system prompt personalizado para el usuario.
     * Este prompt define el rol del asistente y le da contexto específico del opositor.
     */
    private String buildSystemPrompt(ConversacionContexto ctx) {
        if (ctx.getModo() == ChatModo.EXAMINADOR) {
            return buildSystemPromptExaminador(ctx);
        }
        return buildSystemPromptGeneral(ctx);
    }

    private String buildSystemPromptExaminador(ConversacionContexto ctx) {
        StringBuilder sb = new StringBuilder();

        String rama = ctx.getNombreRama() != null ? ctx.getNombreRama() : "oposiciones";
        sb.append("Eres un examinador oficial de ").append(rama).append(" en España. ");
        sb.append("Tu único rol es hacer preguntas tipo test de oposición y evaluar las respuestas del candidato.\n\n");

        sb.append("REGLAS DE COMPORTAMIENTO (obligatorias, sin excepciones):\n");
        sb.append("1. Siempre que el candidato responda, evalúa su respuesta con una puntuación de 0 a 10 y explica brevemente por qué la respuesta es correcta o incorrecta.\n");
        sb.append("2. Tras evaluar, formula INMEDIATAMENTE la siguiente pregunta sin esperar instrucción del usuario.\n");
        sb.append("3. Cada pregunta debe tener 4 opciones (A, B, C, D). Solo una es correcta.\n");
        sb.append("4. Varía los temas y dificultades a lo largo de la sesión.\n");
        sb.append("5. NO respondas preguntas sobre otros temas. Si el candidato dice algo que no sea una respuesta a tu pregunta, recuérdale amablemente que está en modo examinador y formula la pregunta de nuevo.\n");
        sb.append("6. Responde SIEMPRE en español.\n");
        sb.append("7. NO inventes artículos, leyes ni datos normativos. Si no estás seguro de la veracidad o exactitud de una pregunta, omítela y formula una diferente sobre un tema del que tengas certeza.\n");
        sb.append("8. Si el historial de mensajes contiene una conversación general anterior (antes de activar el modo examinador), ignórala por completo. Formula la primera pregunta de test directamente, sin hacer referencia a la conversación previa.\n\n");

        if (ctx.getContenidoDocumental() != null && !ctx.getContenidoDocumental().isBlank()) {
            sb.append("Documento de referencia para las preguntas");
            if (ctx.isContenidoDocumentalEsExtracto()) {
                sb.append(" (extracto)");
            }
            sb.append(":\n---\n");
            sb.append(ctx.getContenidoDocumental());
            sb.append("\n---\n");
            sb.append("Basa las preguntas principalmente en el contenido de este documento.\n\n");
        } else if (ctx.getTemasDebilesDetalle() != null && !ctx.getTemasDebilesDetalle().isEmpty()) {
            sb.append("El candidato tiene dificultades especiales en estos temas (ordena las preguntas priorizándolos):\n");
            ctx.getTemasDebilesDetalle().forEach(t ->
                    sb.append("- ").append(t.getNombre())
                      .append(" (").append(t.getPorcentajeAcierto()).append("% de acierto)\n"));
            sb.append("\n");
        }

        if (ctx.getDiasHastaExamen() != null) {
            sb.append("El candidato tiene el examen en ").append(ctx.getDiasHastaExamen())
              .append(" días. Ajusta la dificultad en consecuencia.\n\n");
        }

        sb.append("Empieza la sesión ahora: formula la primera pregunta directamente, sin preámbulos.\n");

        return sb.toString();
    }

    private String buildSystemPromptGeneral(ConversacionContexto ctx) {
        StringBuilder sb = new StringBuilder();

        if (ctx.getNombreRama() != null) {
            sb.append("Eres un asistente especializado en la preparación de oposiciones para el ")
              .append(ctx.getNombreRama()).append(" en España.\n");
        } else {
            sb.append("Eres un asistente especializado en la preparación de oposiciones en España.\n");
        }

        if (ctx.getFechaExamen() != null) {
            sb.append("El usuario tiene su examen programado para el ").append(ctx.getFechaExamen());
            if (ctx.getDiasHastaExamen() != null) {
                sb.append(" (faltan ").append(ctx.getDiasHastaExamen()).append(" días)");
            }
            sb.append(".\n");
        }

        // 1.1 — Métricas reales de rendimiento (solo si el usuario ya tiene historial)
        boolean tieneHistorial = ctx.getTotalRespuestas() > 0;
        if (tieneHistorial) {
            sb.append("\nRendimiento real del usuario:\n");
            sb.append("- Acierto global: ").append(ctx.getPorcentajeAciertoGlobal())
              .append("% (sobre ").append(ctx.getTotalRespuestas()).append(" respuestas totales)\n");
            if (ctx.getRespuestasEstaSemana() > 0) {
                sb.append("- Esta semana: ").append(ctx.getRespuestasEstaSemana())
                  .append(" respuestas practicadas");
                if (ctx.getPorcentajeAciertoEstaSemana() != null) {
                    sb.append(" (").append(ctx.getPorcentajeAciertoEstaSemana()).append("% de acierto)");
                }
                sb.append("\n");
            }
            if (ctx.getDiasActivosEstaSemana() > 0) {
                sb.append("- Días activos esta semana: ").append(ctx.getDiasActivosEstaSemana()).append("\n");
            }
            if (ctx.getDiasDesdeUltimaActividad() != null && ctx.getDiasDesdeUltimaActividad() > 1) {
                sb.append("- Lleva ").append(ctx.getDiasDesdeUltimaActividad())
                  .append(" día(s) sin practicar.\n");
            }

            if (ctx.getTemasDebilesDetalle() != null && !ctx.getTemasDebilesDetalle().isEmpty()) {
                sb.append("- Temas con menor % de acierto (de peor a mejor):\n");
                ctx.getTemasDebilesDetalle().forEach(t ->
                        sb.append("  · ").append(t.getNombre())
                          .append(": ").append(t.getPorcentajeAcierto()).append("%\n"));
            }
        } else if (ctx.getTemasDebiles() != null && !ctx.getTemasDebiles().isEmpty()) {
            // Fallback: sin historial cuantitativo, solo nombres de temas débiles
            sb.append("Sus temas con menor porcentaje de acierto son: ")
              .append(String.join(", ", ctx.getTemasDebiles())).append(".\n");
        }

        // 1.2 — Recomendaciones proactivas basadas en señales reales del contexto
        sb.append("\nTu comportamiento como tutor personalizado:\n");
        if (tieneHistorial) {
            // Señal: inactividad reciente
            if (ctx.getDiasDesdeUltimaActividad() != null && ctx.getDiasDesdeUltimaActividad() > 2) {
                sb.append("- El usuario lleva ").append(ctx.getDiasDesdeUltimaActividad())
                  .append(" días sin practicar. Si abre esta conversación sin un tema concreto, ")
                  .append("recuérdale con tacto que lleva días sin actividad y proponle retomar hoy ")
                  .append("con su tema más flojo.\n");
            }
            // Señal: bajo acierto semanal
            if (ctx.getPorcentajeAciertoEstaSemana() != null && ctx.getPorcentajeAciertoEstaSemana() < 60.0) {
                sb.append("- Esta semana el usuario acierta solo el ")
                  .append(ctx.getPorcentajeAciertoEstaSemana())
                  .append("% de las respuestas. Cuando encaje naturalmente, sugiere más práctica ")
                  .append("o un repaso en el tema más flojo antes de avanzar a otros.\n");
            }
            // Señal: examen cercano
            if (ctx.getDiasHastaExamen() != null) {
                if (ctx.getDiasHastaExamen() <= 30) {
                    sb.append("- El examen está a solo ").append(ctx.getDiasHastaExamen())
                      .append(" días. Prioriza consolidar los temas débiles con práctica intensiva; ")
                      .append("no es momento de introducir temas nuevos sin base.\n");
                } else if (ctx.getDiasHastaExamen() <= 90) {
                    sb.append("- El examen está a ").append(ctx.getDiasHastaExamen())
                      .append(" días. Hay margen para reforzar los puntos flojos de forma ordenada.\n");
                }
            }
            // Señal: tema concreto más débil
            if (ctx.getTemasDebilesDetalle() != null && !ctx.getTemasDebilesDetalle().isEmpty()) {
                TemaDebilInfo peorTema = ctx.getTemasDebilesDetalle().get(0);
                sb.append("- Cuando el usuario pida orientación o consejo, recomiéndale trabajar hoy en \"")
                  .append(peorTema.getNombre()).append("\" (")
                  .append(peorTema.getPorcentajeAcierto())
                  .append("% de acierto). Menciona el tema por su nombre exacto, no como \"tu tema más débil\".\n");
            }
            sb.append("- Solo incluye recomendaciones cuando el usuario pida orientación, haga una pregunta ")
              .append("abierta o no tenga un tema concreto. Si ya pregunta algo específico, responde ")
              .append("directamente sin desviar la conversación.\n");
            sb.append("- Sé concreto y accionable: nombre del tema + acción (estudiar, practicar, repasar). ")
              .append("Nada de generalidades como \"estudia más\" o \"repasa lo que fallaste\".\n");
        } else {
            sb.append("- Si el usuario pide orientación o consejo de estudio, indícale que aún no tienes ")
              .append("datos de su progreso real. Pídele que complete algunos tests primero para poder ")
              .append("personalizar tus recomendaciones. No inventes datos ni hagas recomendaciones ")
              .append("genéricas sin base en su historial.\n");
        }

        // 1.4 — Contenido de referencia del documento anclado
        if (ctx.getContenidoDocumental() != null && !ctx.getContenidoDocumental().isBlank()) {
            sb.append("\nContenido de referencia");
            if (ctx.isContenidoDocumentalEsExtracto()) {
                sb.append(" (extracto — el documento es más largo; puede estar truncado)");
            }
            sb.append(":\n---\n");
            sb.append(ctx.getContenidoDocumental());
            sb.append("\n---\n");
            sb.append("Cuando el usuario pregunte sobre este documento, úsalo como referencia principal. ");
            if (ctx.isContenidoDocumentalEsExtracto()) {
                sb.append("Si el usuario pregunta algo que no aparece en el extracto, indícale que el documento puede contener más información no cargada.\n");
            }
        }

        if (ctx.getConvocatorias() != null && !ctx.getConvocatorias().isEmpty()) {
            sb.append("\nInformación actualizada sobre convocatorias y noticias relevantes para este usuario:\n");
            ctx.getConvocatorias().forEach(c -> sb.append("- ").append(c).append("\n"));
            sb.append("Usa esta información cuando el usuario pregunte sobre fechas, convocatorias o novedades. ")
              .append("Si no hay información suficiente, indícalo y sugiere consultar el BOE o la web oficial.\n");
        }

        sb.append("""
                Normas de comportamiento:
                - Responde SIEMPRE en español.
                - Sé claro, preciso y útil para alguien que está estudiando para un examen oficial.
                - No inventes artículos, leyes ni datos normativos. Si no estás seguro de algo, indícalo explícitamente.
                - Para preguntas de test, explica por qué la respuesta correcta lo es y por qué las demás son incorrectas.
                - Si el usuario pide un resumen de un tema, organízalo con puntos clave numerados.
                - IMPORTANTE: Únicamente responde preguntas relacionadas con oposiciones, temarios, leyes, procedimientos, \
                historia, geografía u otras materias que formen parte de los exámenes oficiales en España. \
                Si el usuario pregunta sobre cualquier otro tema (tecnología, entretenimiento, vida personal, etc.), \
                responde amablemente que solo puedes ayudar con temas relacionados con la preparación de oposiciones.
                """);

        return sb.toString();
    }  // end buildSystemPromptGeneral

    // ─── Truncado de historial ────────────────────────────────────────────────

    /**
     * Recorta el historial para no superar MAX_HISTORY_CHARS.
     * Prioriza los mensajes más recientes: descarta los más antiguos si se supera el presupuesto.
     * El system prompt y el contexto del usuario no se ven afectados (van por separado).
     */
    private List<ChatMensaje> truncarHistorialPorChars(List<ChatMensaje> historialAsc) {
        int totalChars = 0;
        List<ChatMensaje> resultado = new ArrayList<>();
        // Recorrer de más reciente (último) a más antiguo (primero)
        for (int i = historialAsc.size() - 1; i >= 0; i--) {
            int len = historialAsc.get(i).getMensaje().length();
            if (totalChars + len > MAX_HISTORY_CHARS) {
                log.info("Historial truncado: se descartaron {} mensaje(s) antiguo(s) " +
                         "(presupuesto {} chars superado; acumulado antes del corte: {} chars)",
                        i + 1, MAX_HISTORY_CHARS, totalChars);
                break;
            }
            totalChars += len;
            resultado.add(0, historialAsc.get(i));
        }
        return resultado;
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private ChatConversacion findByIdAndOwner(Long conversacionId, Long usuarioId) {
        return conversacionRepository.findByIdAndUsuarioId(conversacionId, usuarioId)
                .orElseThrow(() -> new AppException("Conversación no encontrada", HttpStatus.NOT_FOUND));
    }

    private RamaOposicion resolveRama(Long ramaId) {
        if (ramaId == null) return null;
        return ramaRepository.findById(ramaId).orElse(null);
    }

    private ConversacionContexto leerContexto(ChatConversacion conversacion) {
        try {
            return objectMapper.readValue(conversacion.getContexto(), ConversacionContexto.class);
        } catch (JsonProcessingException e) {
            return ConversacionContexto.builder().build();
        }
    }

    private String escribirContexto(ConversacionContexto contexto) {
        try {
            return objectMapper.writeValueAsString(contexto);
        } catch (JsonProcessingException e) {
            throw new AppException("Error al serializar el contexto de la conversación",
                    HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    private Usuario findUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new AppException("Usuario no encontrado", HttpStatus.NOT_FOUND));
    }

    // ─── Helpers internos ────────────────────────────────────────────────────

    private static boolean esErrorRateLimit(Exception e) {
        return contieneRateLimit(e.getMessage())
                || (e.getCause() != null && contieneRateLimit(e.getCause().getMessage()));
    }

    private static boolean contieneRateLimit(String msg) {
        if (msg == null) return false;
        String lower = msg.toLowerCase();
        return lower.contains("429")
                || lower.contains("rate limit")
                || lower.contains("too many requests")
                || lower.contains("too_many");
    }

    // ─── Mapping ──────────────────────────────────────────────────────────────

    private ConversacionResponse toConversacionResponse(ChatConversacion c, ConversacionContexto ctx) {
        return ConversacionResponse.builder()
                .id(c.getId())
                .nombreRama(ctx.getNombreRama())
                .fechaExamen(ctx.getFechaExamen())
                .temasDebiles(ctx.getTemasDebiles())
                .createdAt(c.getCreatedAt())
                .nombreDocumento(ctx.getNombreDocumento())
                .modo(c.getModo())
                .build();
    }

    private MensajeResponse toMensajeResponse(ChatMensaje m) {
        return MensajeResponse.builder()
                .id(m.getId())
                .esIa(m.isEsIa())
                .mensaje(m.getMensaje())
                .createdAt(m.getCreatedAt())
                .build();
    }
}
