package com.oposites.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.oposites.api.exception.AppException;
import com.oposites.api.model.dto.request.ResponderRepasoRequest;
import com.oposites.api.model.dto.response.IniciarSesionRepasoResponse;
import com.oposites.api.model.dto.response.ResponderRepasoResponse;
import com.oposites.api.model.dto.response.ResultadoSesionRepasoResponse;
import com.oposites.api.model.entity.*;
import com.oposites.api.model.enums.EstadoSesionRepaso;
import com.oposites.api.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class SesionRepasoService {

    private static final int PREGUNTAS_POR_SESION = 10;
    private static final int MAX_TEMAS_POR_SESION = 3;
    /** Mínimo de respuestas en un tema para considerarlo "con historial suficiente". */
    private static final int MIN_RESPUESTAS_TEMA = 3;

    private final ChatClient chatClient;
    private final UsuarioRepository usuarioRepository;
    private final RamaOposicionRepository ramaRepository;
    private final TemaRepository temaRepository;
    private final ProgresoUsuarioRepository progresoRepository;
    private final SesionRepasoRepository sesionRepasoRepository;
    private final RespuestaSesionRepasoRepository respuestaRepository;
    private final ObjectMapper objectMapper;

    // ─── Endpoints ────────────────────────────────────────────────────────────

    @Transactional
    public IniciarSesionRepasoResponse iniciar(String email) {
        Usuario usuario = findUsuario(email);
        Long ramaId = usuario.getRamaPrincipalId();
        RamaOposicion rama = ramaId != null
                ? ramaRepository.findById(ramaId).orElse(null)
                : null;

        // Intentar recuperar sesión EN_CURSO existente antes de crear una nueva
        Optional<SesionRepaso> sesionActiva = sesionRepasoRepository
                .findFirstByUsuarioIdAndEstadoOrderByCreatedAtDesc(usuario.getId(), EstadoSesionRepaso.EN_CURSO);

        if (sesionActiva.isPresent()) {
            SesionRepaso sesion = sesionActiva.get();
            long yaRespondidas = respuestaRepository.countBySesionRepasoId(sesion.getId());
            if (yaRespondidas < sesion.getTotalPreguntas()) {
                log.info("Sesión de repaso {} recuperada para usuario {} ({}/{} respondidas)",
                        sesion.getId(), usuario.getId(), yaRespondidas, sesion.getTotalPreguntas());
                return toIniciarResponse(sesion, (int) yaRespondidas);
            }
            // Todas las preguntas ya respondidas pero sesión no cerrada → cerrar limpiamente
            sesion.setEstado(EstadoSesionRepaso.COMPLETADA);
            sesionRepasoRepository.save(sesion);
        }

        // Expirar sesiones anteriores en curso
        sesionRepasoRepository.expirarSesionesActivas(
                usuario.getId(), EstadoSesionRepaso.EN_CURSO, EstadoSesionRepaso.COMPLETADA);

        // Seleccionar temas débiles
        List<SesionRepaso.TemaRepasoInfo> temas = seleccionarTemas(usuario, ramaId);

        if (temas.isEmpty()) {
            throw new AppException(
                    "No se puede generar el repaso: asegúrate de tener una oposición configurada " +
                    "y de que tu rama tenga temas disponibles.",
                    HttpStatus.BAD_REQUEST);
        }

        // Generar preguntas via LLM
        List<SesionRepaso.PreguntaRepaso> preguntas = generarPreguntas(temas, rama);

        SesionRepaso sesion = SesionRepaso.builder()
                .usuario(usuario)
                .rama(rama)
                .temas(temas)
                .preguntas(preguntas)
                .totalPreguntas(preguntas.size())
                .build();

        sesionRepasoRepository.save(sesion);

        return toIniciarResponse(sesion, 0);
    }

    @Transactional
    public ResponderRepasoResponse responder(Long sesionId, String email,
                                             ResponderRepasoRequest request) {
        Usuario usuario = findUsuario(email);
        SesionRepaso sesion = findByIdAndOwner(sesionId, usuario.getId());

        if (sesion.getEstado() != EstadoSesionRepaso.EN_CURSO) {
            throw new AppException("La sesión ya fue completada", HttpStatus.BAD_REQUEST);
        }

        int idx = request.getPreguntaIndex();
        if (idx < 0 || idx >= sesion.getPreguntas().size()) {
            throw new AppException("Índice de pregunta inválido", HttpStatus.BAD_REQUEST);
        }
        if (respuestaRepository.existsBySesionRepasoIdAndPreguntaIndex(sesionId, idx)) {
            throw new AppException("Esta pregunta ya fue respondida", HttpStatus.BAD_REQUEST);
        }

        SesionRepaso.PreguntaRepaso pregunta = sesion.getPreguntas().get(idx);
        boolean esCorrecta = request.getRespuestaUsuario() == pregunta.getRespuestaCorrecta();

        // Tema para el registro de progreso
        Tema tema = pregunta.getTemaId() != null
                ? temaRepository.findById(pregunta.getTemaId()).orElse(null)
                : null;

        // Registrar en respuestas de la sesión
        respuestaRepository.save(RespuestaSesionRepaso.builder()
                .sesionRepaso(sesion)
                .preguntaIndex(idx)
                .tema(tema)
                .respuestaUsuario(request.getRespuestaUsuario())
                .esCorrecta(esCorrecta)
                .build());

        // Impactar ProgresoUsuario (pregunta=null, tema=direct)
        progresoRepository.save(ProgresoUsuario.builder()
                .usuario(usuario)
                .tema(tema)
                .respuestaUsuario(String.valueOf(request.getRespuestaUsuario()))
                .correcto(esCorrecta)
                .build());

        // Comprobar si es la última pregunta → auto-completar sesión
        long totalRespondidas = respuestaRepository.countBySesionRepasoId(sesionId);
        boolean sesionCompletada = totalRespondidas >= sesion.getTotalPreguntas();
        Double puntuacion = null;

        if (sesionCompletada) {
            List<RespuestaSesionRepaso> todas = respuestaRepository
                    .findBySesionRepasoIdOrderByPreguntaIndexAsc(sesionId);
            int correctas = (int) todas.stream().filter(RespuestaSesionRepaso::isEsCorrecta).count();
            puntuacion = calcularPuntuacion(correctas, sesion.getTotalPreguntas());

            sesion.setCorretas(correctas);
            sesion.setPuntuacion(puntuacion);
            sesion.setEstado(EstadoSesionRepaso.COMPLETADA);
            sesion.setCompletadoAt(java.time.LocalDateTime.now());
            sesionRepasoRepository.save(sesion);
        }

        return ResponderRepasoResponse.builder()
                .esCorrecta(esCorrecta)
                .respuestaCorrecta(pregunta.getRespuestaCorrecta())
                .explicacion(pregunta.getExplicacion())
                .sesionCompletada(sesionCompletada)
                .puntuacion(puntuacion)
                .build();
    }

    public ResultadoSesionRepasoResponse obtenerResultado(Long sesionId, String email) {
        SesionRepaso sesion = findByIdAndOwner(sesionId, findUsuario(email).getId());

        List<RespuestaSesionRepaso> respuestas = respuestaRepository
                .findBySesionRepasoIdOrderByPreguntaIndexAsc(sesionId);

        Map<Integer, RespuestaSesionRepaso> porIndice = respuestas.stream()
                .collect(Collectors.toMap(RespuestaSesionRepaso::getPreguntaIndex, r -> r));

        List<ResultadoSesionRepasoResponse.DetalleRespuestaDto> detalle = new ArrayList<>();
        for (int i = 0; i < sesion.getPreguntas().size(); i++) {
            SesionRepaso.PreguntaRepaso p = sesion.getPreguntas().get(i);
            RespuestaSesionRepaso r = porIndice.get(i);
            detalle.add(ResultadoSesionRepasoResponse.DetalleRespuestaDto.builder()
                    .preguntaIndex(i)
                    .enunciado(p.getEnunciado())
                    .esCorrecta(r != null && r.isEsCorrecta())
                    .temaNombre(p.getTemaNombre())
                    .respuestaUsuario(r != null ? r.getRespuestaUsuario() : -1)
                    .respuestaCorrecta(p.getRespuestaCorrecta())
                    .explicacion(p.getExplicacion())
                    .build());
        }

        int correctas = sesion.getCorretas() != null ? sesion.getCorretas() : 0;
        double puntuacion = sesion.getPuntuacion() != null ? sesion.getPuntuacion() : 0.0;

        return ResultadoSesionRepasoResponse.builder()
                .sesionId(sesion.getId())
                .puntuacion(puntuacion)
                .totalPreguntas(sesion.getTotalPreguntas())
                .correctas(correctas)
                .respuestas(detalle)
                .build();
    }

    // ─── Selección de temas débiles ───────────────────────────────────────────

    private List<SesionRepaso.TemaRepasoInfo> seleccionarTemas(Usuario usuario, Long ramaId) {
        if (ramaId == null) return List.of();

        // Top temas débiles con historial suficiente
        List<Long> temasDebiles = progresoRepository.findTemaIdsOrdenadosPorDebilidad(
                usuario.getId(), ramaId, PageRequest.of(0, MAX_TEMAS_POR_SESION * 2));

        // Estadísticas para calcular % de acierto por tema
        List<Object[]> stats = progresoRepository.findEstadisticasPorTema(usuario.getId(), ramaId);
        Map<Long, Long[]> statsPorTema = stats.stream()
                .collect(Collectors.toMap(
                        row -> ((Number) row[0]).longValue(),
                        row -> new Long[]{((Number) row[1]).longValue(), ((Number) row[2]).longValue()}
                ));

        // Filtrar por umbral mínimo de respuestas
        List<Long> temasFiltrados = temasDebiles.stream()
                .filter(id -> {
                    Long[] s = statsPorTema.get(id);
                    return s != null && s[0] >= MIN_RESPUESTAS_TEMA;
                })
                .limit(MAX_TEMAS_POR_SESION)
                .collect(Collectors.toCollection(ArrayList::new));

        // Fallback: si hay menos de MAX_TEMAS, completar con temas aleatorios de la rama
        if (temasFiltrados.size() < MAX_TEMAS_POR_SESION) {
            List<Long> todosLosTemas = temaRepository.findByRamaIdOrderByOrden(ramaId)
                    .stream().map(Tema::getId).collect(Collectors.toList());
            todosLosTemas.removeAll(temasFiltrados);
            Collections.shuffle(todosLosTemas);
            int faltan = MAX_TEMAS_POR_SESION - temasFiltrados.size();
            temasFiltrados.addAll(todosLosTemas.stream().limit(faltan).toList());
        }

        if (temasFiltrados.isEmpty()) return List.of();

        // Construir TemaRepasoInfo con nombre y % de acierto
        Map<Long, Tema> temasPorId = temaRepository.findAllById(temasFiltrados)
                .stream().collect(Collectors.toMap(Tema::getId, t -> t));

        return temasFiltrados.stream()
                .filter(temasPorId::containsKey)
                .map(id -> {
                    Long[] s = statsPorTema.get(id);
                    double pct = (s != null && s[0] > 0)
                            ? Math.round(s[1] * 100.0 / s[0] * 10.0) / 10.0
                            : 0.0;
                    return SesionRepaso.TemaRepasoInfo.builder()
                            .id(id)
                            .nombre(temasPorId.get(id).getNombre())
                            .porcentajeAcierto(pct)
                            .build();
                })
                .toList();
    }

    // ─── Generación de preguntas via LLM ─────────────────────────────────────

    private List<SesionRepaso.PreguntaRepaso> generarPreguntas(
            List<SesionRepaso.TemaRepasoInfo> temas, RamaOposicion rama) {

        String systemPrompt = buildPromptGeneracion(rama);
        String userPrompt = buildUserPromptGeneracion(temas);

        String respuestaLlm;
        try {
            respuestaLlm = chatClient.prompt()
                    .messages(new SystemMessage(systemPrompt), new UserMessage(userPrompt))
                    .call()
                    .content();
        } catch (Exception e) {
            throw new AppException(
                    "El servicio de IA no está disponible. Inténtalo de nuevo.",
                    HttpStatus.SERVICE_UNAVAILABLE);
        }

        return parsearPreguntas(extraerJson(respuestaLlm), temas);
    }

    private String buildPromptGeneracion(RamaOposicion rama) {
        String nombreRama = rama != null ? rama.getNombre() : "oposiciones en España";
        return """
                Eres un experto en elaboración de preguntas de test para %s.
                Crea exactamente %d preguntas de opción múltiple (MCQ) basadas en los temas indicados.
                Distribuye las preguntas de forma equilibrada entre los temas proporcionados.
                Cada pregunta debe tener exactamente 4 opciones y una única respuesta correcta.
                Responde EXCLUSIVAMENTE con un JSON válido, sin texto adicional ni bloques de código markdown.
                Formato exacto:
                {"preguntas":[{"enunciado":"...","opciones":["A) ...","B) ...","C) ...","D) ..."],"respuestaCorrecta":0,"explicacion":"...","temaId":0,"temaNombre":"..."}]}
                - "respuestaCorrecta" es el índice (0-3) de la opción correcta.
                - "explicacion" justifica brevemente por qué esa opción es correcta (máximo 2 frases).
                - "temaId" debe coincidir exactamente con el id del tema proporcionado.
                - "temaNombre" debe coincidir exactamente con el nombre del tema proporcionado.
                IMPORTANTE: NO inventes artículos, leyes ni datos normativos. Si no estás seguro de la veracidad o exactitud de una pregunta, omítela y formula una diferente sobre un concepto del que tengas certeza.
                """.formatted(nombreRama, PREGUNTAS_POR_SESION);
    }

    private String buildUserPromptGeneracion(List<SesionRepaso.TemaRepasoInfo> temas) {
        StringBuilder sb = new StringBuilder("Genera preguntas sobre los siguientes temas:\n");
        temas.forEach(t -> sb.append("- Tema id=%d | nombre=\"%s\" | acierto actual=%.1f%%\n"
                .formatted(t.getId(), t.getNombre(), t.getPorcentajeAcierto())));
        sb.append("\nPrioriza los temas con menor porcentaje de acierto. Total: %d preguntas."
                .formatted(PREGUNTAS_POR_SESION));
        return sb.toString();
    }

    private String extraerJson(String respuesta) {
        String limpio = respuesta.strip();
        if (limpio.startsWith("```")) {
            int inicio = limpio.indexOf('{');
            int fin = limpio.lastIndexOf('}');
            if (inicio != -1 && fin != -1) {
                limpio = limpio.substring(inicio, fin + 1).strip();
            }
        }
        try {
            objectMapper.readTree(limpio);
            return limpio;
        } catch (JsonProcessingException e) {
            log.error("IA devolvió JSON inválido para repaso: {}", limpio);
            throw new AppException(
                    "La IA devolvió una respuesta con formato incorrecto. Inténtalo de nuevo.",
                    HttpStatus.BAD_GATEWAY);
        }
    }

    private List<SesionRepaso.PreguntaRepaso> parsearPreguntas(
            String json, List<SesionRepaso.TemaRepasoInfo> temas) {
        try {
            JsonNode root = objectMapper.readTree(json);
            JsonNode array = root.path("preguntas");
            if (!array.isArray() || array.isEmpty()) {
                throw new AppException(
                        "La IA no generó preguntas válidas. Inténtalo de nuevo.",
                        HttpStatus.BAD_GATEWAY);
            }

            // índice rápido por id para validar temas del JSON
            Map<Long, SesionRepaso.TemaRepasoInfo> temasPorId = temas.stream()
                    .collect(Collectors.toMap(SesionRepaso.TemaRepasoInfo::getId, t -> t));

            List<SesionRepaso.PreguntaRepaso> result = new ArrayList<>();
            for (JsonNode nodo : array) {
                // Validación: enunciado no vacío
                String enunciado = nodo.path("enunciado").asText("").strip();
                if (enunciado.isEmpty()) {
                    log.warn("Pregunta sin enunciado devuelta por la IA en repaso, se omite");
                    continue;
                }

                // Validación: exactamente 4 opciones
                List<String> opciones = new ArrayList<>();
                nodo.path("opciones").forEach(o -> opciones.add(o.asText()));
                if (opciones.size() != 4) {
                    log.warn("Pregunta con {} opciones (esperadas 4) devuelta por la IA en repaso, se omite",
                            opciones.size());
                    continue;
                }

                // Validación: respuestaCorrecta presente y entre 0-3
                JsonNode rcNode = nodo.path("respuestaCorrecta");
                if (rcNode.isMissingNode() || rcNode.isNull()) {
                    log.warn("Pregunta sin respuestaCorrecta devuelta por la IA en repaso, se omite");
                    continue;
                }
                int respuestaCorrecta = rcNode.asInt(-1);
                if (respuestaCorrecta < 0 || respuestaCorrecta > 3) {
                    log.warn("Pregunta con respuestaCorrecta={} fuera de rango en repaso, se omite",
                            respuestaCorrecta);
                    continue;
                }

                long temaId = nodo.path("temaId").asLong(0);
                String temaNombre = nodo.path("temaNombre").asText("");
                // Si el LLM devuelve un temaId que no conocemos, usar el primero disponible
                if (!temasPorId.containsKey(temaId) && !temas.isEmpty()) {
                    temaId = temas.get(0).getId();
                    temaNombre = temas.get(0).getNombre();
                }

                result.add(SesionRepaso.PreguntaRepaso.builder()
                        .enunciado(enunciado)
                        .opciones(opciones)
                        .respuestaCorrecta(respuestaCorrecta)
                        .explicacion(nodo.path("explicacion").asText(""))
                        .temaId(temaId)
                        .temaNombre(temaNombre)
                        .build());

                if (result.size() == PREGUNTAS_POR_SESION) break;
            }

            if (result.isEmpty()) {
                throw new AppException(
                        "La IA no pudo generar preguntas válidas para el repaso. Inténtalo de nuevo.",
                        HttpStatus.BAD_GATEWAY);
            }

            return result;
        } catch (JsonProcessingException e) {
            throw new AppException("Error al procesar las preguntas generadas.", HttpStatus.BAD_GATEWAY);
        }
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private SesionRepaso findByIdAndOwner(Long sesionId, Long usuarioId) {
        return sesionRepasoRepository.findByIdAndUsuarioId(sesionId, usuarioId)
                .orElseThrow(() -> new AppException("Sesión no encontrada", HttpStatus.NOT_FOUND));
    }

    private Usuario findUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new AppException("Usuario no encontrado", HttpStatus.NOT_FOUND));
    }

    private double calcularPuntuacion(int correctas, int total) {
        if (total == 0) return 0.0;
        return Math.round((double) correctas / total * 100.0) / 10.0;
    }

    // ─── Mapping ──────────────────────────────────────────────────────────────

    private IniciarSesionRepasoResponse toIniciarResponse(SesionRepaso sesion, int preguntaActual) {
        List<IniciarSesionRepasoResponse.TemaRepasoDto> temasDto = sesion.getTemas().stream()
                .map(t -> IniciarSesionRepasoResponse.TemaRepasoDto.builder()
                        .id(t.getId())
                        .nombre(t.getNombre())
                        .porcentajeAcierto(t.getPorcentajeAcierto())
                        .build())
                .toList();

        List<IniciarSesionRepasoResponse.PreguntaRepasoDto> preguntasDto = new ArrayList<>();
        for (int i = 0; i < sesion.getPreguntas().size(); i++) {
            SesionRepaso.PreguntaRepaso p = sesion.getPreguntas().get(i);
            preguntasDto.add(IniciarSesionRepasoResponse.PreguntaRepasoDto.builder()
                    .index(i)
                    .enunciado(p.getEnunciado())
                    .opciones(p.getOpciones())
                    .temaNombre(p.getTemaNombre())
                    .build());
        }

        return IniciarSesionRepasoResponse.builder()
                .sesionId(sesion.getId())
                .totalPreguntas(sesion.getTotalPreguntas())
                .preguntaActual(preguntaActual)
                .temas(temasDto)
                .preguntas(preguntasDto)
                .build();
    }
}
