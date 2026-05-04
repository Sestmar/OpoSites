package com.oposites.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.oposites.api.exception.AppException;
import com.oposites.api.model.dto.response.DocumentoTestPreguntaResponse;
import com.oposites.api.model.dto.response.DocumentoTestResponse;
import com.oposites.api.model.entity.Documento;
import com.oposites.api.model.entity.DocumentoTest;
import com.oposites.api.model.entity.DocumentoTestPregunta;
import com.oposites.api.model.entity.Usuario;
import com.oposites.api.repository.DocumentoRepository;
import com.oposites.api.repository.DocumentoTestRepository;
import com.oposites.api.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class DocumentoTestService {

    private static final int MAX_CHARS_TEXTO = 10_000;

    private final DocumentoTestRepository testRepository;
    private final DocumentoRepository documentoRepository;
    private final UsuarioRepository usuarioRepository;
    private final ChatClient chatClient;
    private final ObjectMapper objectMapper;

    // ─── Endpoints ────────────────────────────────────────────────────────────

    @Transactional
    public DocumentoTestResponse generarTest(Long documentoId, String email) {
        Long usuarioId = findUsuario(email).getId();
        Documento documento = findDocumentoByOwner(documentoId, usuarioId);

        if (documento.getTextoExtraido() == null || documento.getTextoExtraido().isBlank()) {
            throw new AppException(
                    "No se pudo extraer texto de este documento. Verifica que no sea un PDF escaneado.",
                    HttpStatus.UNPROCESSABLE_ENTITY);
        }

        String texto = truncar(documento.getTextoExtraido());
        List<DocumentoTestPregunta> preguntas = generarPreguntas(texto);

        DocumentoTest test = DocumentoTest.builder()
                .documento(documento)
                .build();

        for (int i = 0; i < preguntas.size(); i++) {
            DocumentoTestPregunta p = preguntas.get(i);
            p.setTest(test);
            p.setOrden(i);
        }
        test.getPreguntas().addAll(preguntas);

        return toResponse(testRepository.save(test));
    }

    @Transactional(readOnly = true)
    public DocumentoTestResponse obtenerUltimo(Long documentoId, String email) {
        Long usuarioId = findUsuario(email).getId();
        findDocumentoByOwner(documentoId, usuarioId); // ownership check

        return testRepository.findTopByDocumentoIdOrderByCreadoEnDesc(documentoId)
                .map(this::toResponse)
                .orElseThrow(() -> new AppException(
                        "Este documento todavía no tiene ningún test generado.",
                        HttpStatus.NOT_FOUND));
    }

    @Transactional(readOnly = true)
    public DocumentoTestResponse obtenerPorId(Long documentoId, Long testId, String email) {
        Long usuarioId = findUsuario(email).getId();
        findDocumentoByOwner(documentoId, usuarioId); // ownership check

        DocumentoTest test = testRepository.findById(testId)
                .orElseThrow(() -> new AppException("Test no encontrado.", HttpStatus.NOT_FOUND));

        if (!test.getDocumento().getId().equals(documentoId)) {
            throw new AppException("Test no encontrado.", HttpStatus.NOT_FOUND);
        }

        return toResponse(test);
    }

    // ─── Generación con IA ────────────────────────────────────────────────────

    private List<DocumentoTestPregunta> generarPreguntas(String texto) {
        String systemPrompt = """
                Eres un experto en elaboración de test para oposiciones en España.
                Crea entre 8 y 10 preguntas de opción múltiple (MCQ) a partir del documento proporcionado.
                Cada pregunta debe tener exactamente 4 opciones y una única respuesta correcta.
                Responde EXCLUSIVAMENTE con un JSON válido, sin texto adicional ni bloques de código markdown.
                Formato exacto:
                {"preguntas":[{"enunciado":"...","opciones":["A...","B...","C...","D..."],"respuestaCorrecta":0,"explicacion":"..."}]}
                - "respuestaCorrecta" es el índice (0-3) de la opción correcta.
                - "explicacion" debe justificar brevemente por qué esa opción es correcta.
                - Las preguntas deben cubrir los puntos más relevantes del documento.
                - Usa el idioma del documento original.
                """;
        String userPrompt = "Documento a analizar:\n---\n" + texto + "\n---";

        String respuesta;
        try {
            respuesta = chatClient.prompt()
                    .messages(new SystemMessage(systemPrompt), new UserMessage(userPrompt))
                    .call()
                    .content();
        } catch (Exception e) {
            throw new AppException(
                    "El servicio de IA no está disponible. Inténtalo de nuevo.",
                    HttpStatus.SERVICE_UNAVAILABLE);
        }

        return parsearPreguntas(limpiarJson(respuesta));
    }

    private String limpiarJson(String respuesta) {
        String limpio = respuesta.strip();
        if (limpio.startsWith("```")) {
            int inicio = limpio.indexOf('\n');
            int fin = limpio.lastIndexOf("```");
            if (inicio != -1 && fin > inicio) {
                limpio = limpio.substring(inicio + 1, fin).strip();
            }
        }
        return limpio;
    }

    private List<DocumentoTestPregunta> parsearPreguntas(String json) {
        try {
            JsonNode root = objectMapper.readTree(json);
            JsonNode preguntasNode = root.get("preguntas");

            if (preguntasNode == null || !preguntasNode.isArray()) {
                throw new AppException(
                        "La IA devolvió una respuesta con formato incorrecto. Inténtalo de nuevo.",
                        HttpStatus.BAD_GATEWAY);
            }

            List<DocumentoTestPregunta> lista = new ArrayList<>();
            for (JsonNode pNode : preguntasNode) {
                List<String> opciones = new ArrayList<>();
                pNode.get("opciones").forEach(op -> opciones.add(op.asText()));

                lista.add(DocumentoTestPregunta.builder()
                        .enunciado(pNode.get("enunciado").asText())
                        .opciones(opciones)
                        .respuestaCorrecta(pNode.get("respuestaCorrecta").asInt())
                        .explicacion(pNode.get("explicacion").asText())
                        .orden(0) // será sobreescrito al insertar
                        .build());
            }
            return lista;

        } catch (AppException e) {
            throw e;
        } catch (JsonProcessingException e) {
            log.error("IA devolvió JSON inválido para test: {}", json);
            throw new AppException(
                    "La IA devolvió una respuesta con formato incorrecto. Inténtalo de nuevo.",
                    HttpStatus.BAD_GATEWAY);
        }
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private String truncar(String texto) {
        return texto.length() > MAX_CHARS_TEXTO ? texto.substring(0, MAX_CHARS_TEXTO) : texto;
    }

    private Documento findDocumentoByOwner(Long documentoId, Long usuarioId) {
        return documentoRepository.findByIdAndUsuarioId(documentoId, usuarioId)
                .orElseThrow(() -> new AppException("Documento no encontrado.", HttpStatus.NOT_FOUND));
    }

    private Usuario findUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new AppException("Usuario no encontrado.", HttpStatus.NOT_FOUND));
    }

    // ─── Mapping ──────────────────────────────────────────────────────────────

    private DocumentoTestResponse toResponse(DocumentoTest test) {
        List<DocumentoTestPreguntaResponse> preguntas = test.getPreguntas().stream()
                .map(p -> DocumentoTestPreguntaResponse.builder()
                        .id(p.getId())
                        .enunciado(p.getEnunciado())
                        .opciones(p.getOpciones())
                        .respuestaCorrecta(p.getRespuestaCorrecta())
                        .explicacion(p.getExplicacion())
                        .orden(p.getOrden())
                        .build())
                .toList();

        return DocumentoTestResponse.builder()
                .id(test.getId())
                .documentoId(test.getDocumento().getId())
                .preguntas(preguntas)
                .creadoEn(test.getCreadoEn())
                .build();
    }
}
