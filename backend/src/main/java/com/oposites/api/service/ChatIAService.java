package com.oposites.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.oposites.api.exception.AppException;
import com.oposites.api.model.chat.ConversacionContexto;
import com.oposites.api.model.dto.request.EnviarMensajeRequest;
import com.oposites.api.model.dto.response.ConversacionResponse;
import com.oposites.api.model.dto.response.EnviarMensajeResponse;
import com.oposites.api.model.dto.response.MensajeResponse;
import com.oposites.api.model.entity.ChatConversacion;
import com.oposites.api.model.entity.ChatMensaje;
import com.oposites.api.model.entity.RamaOposicion;
import com.oposites.api.model.entity.Tema;
import com.oposites.api.model.entity.Usuario;
import com.oposites.api.repository.ChatConversacionRepository;
import com.oposites.api.repository.ChatMensajeRepository;
import com.oposites.api.repository.ProgresoUsuarioRepository;
import com.oposites.api.repository.RamaOposicionRepository;
import com.oposites.api.repository.TemaRepository;
import com.oposites.api.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ChatIAService {

    // Número de mensajes anteriores que se envían al LLM como contexto de conversación
    private static final int VENTANA_HISTORIAL = 20;
    // Número de temas débiles incluidos en el system prompt
    private static final int TOP_TEMAS_DEBILES = 3;

    private final ChatClient chatClient;
    private final ChatConversacionRepository conversacionRepository;
    private final ChatMensajeRepository mensajeRepository;
    private final UsuarioRepository usuarioRepository;
    private final RamaOposicionRepository ramaRepository;
    private final TemaRepository temaRepository;
    private final ProgresoUsuarioRepository progresoRepository;
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
    public ConversacionResponse crearConversacion(String email) {
        Usuario usuario = findUsuario(email);
        RamaOposicion rama = resolveRama(usuario.getRamaPrincipalId());
        ConversacionContexto contexto = buildContexto(usuario, rama);

        ChatConversacion conversacion = ChatConversacion.builder()
                .usuario(usuario)
                .rama(rama)
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

        // 1. Persiste el mensaje del usuario
        mensajeRepository.save(ChatMensaje.builder()
                .conversacion(conversacion)
                .esIa(false)
                .mensaje(request.getMensaje())
                .build());

        // 2. Recupera la ventana de historial (DESC → revertir a ASC para el LLM)
        List<ChatMensaje> historialDesc = mensajeRepository
                .findTop20ByConversacionIdOrderByCreatedAtDesc(conversacionId);
        List<ChatMensaje> historialAsc = new ArrayList<>(historialDesc);
        Collections.reverse(historialAsc);

        // 3. Construye los mensajes para el LLM
        ConversacionContexto contexto = leerContexto(conversacion);
        List<Message> llmMessages = new ArrayList<>();
        llmMessages.add(new SystemMessage(buildSystemPrompt(contexto)));

        for (ChatMensaje m : historialAsc) {
            llmMessages.add(m.isEsIa()
                    ? new AssistantMessage(m.getMensaje())
                    : new UserMessage(m.getMensaje()));
        }

        // 4. Llama al LLM (gemini-2.0-flash vía endpoint OpenAI-compatible)
        String respuestaTexto;
        try {
            respuestaTexto = chatClient.prompt()
                    .messages(llmMessages)
                    .call()
                    .content();
        } catch (Exception e) {
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
    public void eliminarConversacion(Long conversacionId, String email) {
        ChatConversacion conversacion = findByIdAndOwner(conversacionId, findUsuario(email).getId());
        conversacionRepository.delete(conversacion);
    }

    // ─── Construcción del contexto y system prompt ────────────────────────────

    private ConversacionContexto buildContexto(Usuario usuario, RamaOposicion rama) {
        String nombreRama = rama != null ? rama.getNombre() : null;
        String fechaExamen = usuario.getFechaExamenObjetivo() != null
                ? usuario.getFechaExamenObjetivo().toString()
                : null;

        List<String> temasDebiles = List.of();
        if (usuario.getRamaPrincipalId() != null) {
            List<Long> temaIds = progresoRepository.findTemaIdsOrdenadosPorDebilidad(
                    usuario.getId(), usuario.getRamaPrincipalId(),
                    PageRequest.of(0, TOP_TEMAS_DEBILES));
            if (!temaIds.isEmpty()) {
                temasDebiles = temaRepository.findAllById(temaIds)
                        .stream()
                        .map(Tema::getNombre)
                        .toList();
            }
        }

        return ConversacionContexto.builder()
                .nombreRama(nombreRama)
                .fechaExamen(fechaExamen)
                .temasDebiles(temasDebiles)
                .build();
    }

    /**
     * Construye el system prompt personalizado para el usuario.
     * Este prompt define el rol del asistente y le da contexto específico del opositor.
     */
    private String buildSystemPrompt(ConversacionContexto ctx) {
        StringBuilder sb = new StringBuilder();

        if (ctx.getNombreRama() != null) {
            sb.append("Eres un asistente especializado en la preparación de oposiciones para el ")
              .append(ctx.getNombreRama()).append(" en España.\n");
        } else {
            sb.append("Eres un asistente especializado en la preparación de oposiciones en España.\n");
        }

        if (ctx.getFechaExamen() != null) {
            sb.append("El usuario tiene su examen programado para el ").append(ctx.getFechaExamen()).append(".\n");
        }

        if (ctx.getTemasDebiles() != null && !ctx.getTemasDebiles().isEmpty()) {
            sb.append("Sus temas con menor porcentaje de acierto son: ")
              .append(String.join(", ", ctx.getTemasDebiles())).append(".\n");
        }

        sb.append("""
                Normas de comportamiento:
                - Responde SIEMPRE en español.
                - Sé claro, preciso y útil para alguien que está estudiando para un examen oficial.
                - No inventes artículos, leyes ni datos normativos. Si no estás seguro de algo, indícalo explícitamente.
                - Para preguntas de test, explica por qué la respuesta correcta lo es y por qué las demás son incorrectas.
                - Si el usuario pide un resumen de un tema, organízalo con puntos clave numerados.
                """);

        return sb.toString();
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

    // ─── Mapping ──────────────────────────────────────────────────────────────

    private ConversacionResponse toConversacionResponse(ChatConversacion c, ConversacionContexto ctx) {
        return ConversacionResponse.builder()
                .id(c.getId())
                .nombreRama(ctx.getNombreRama())
                .fechaExamen(ctx.getFechaExamen())
                .temasDebiles(ctx.getTemasDebiles())
                .createdAt(c.getCreatedAt())
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
