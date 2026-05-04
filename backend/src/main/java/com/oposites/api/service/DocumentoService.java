package com.oposites.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.oposites.api.exception.AppException;
import com.oposites.api.model.dto.request.GenerarMaterialRequest;
import com.oposites.api.model.dto.response.DocumentoResponse;
import com.oposites.api.model.dto.response.MaterialGeneradoResponse;
import com.oposites.api.model.entity.Documento;
import com.oposites.api.model.entity.MaterialGenerado;
import com.oposites.api.model.entity.Usuario;
import com.oposites.api.model.enums.TipoMaterial;
import com.oposites.api.repository.DocumentoRepository;
import com.oposites.api.repository.MaterialGeneradoRepository;
import com.oposites.api.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class DocumentoService {

    // Número máximo de caracteres del texto extraído que se envía al LLM.
    // ~2.500 tokens ≈ 10.000 caracteres. Groq free tier tiene límite de 12.000 TPM
    // (tokens por minuto). Con este valor cada generación consume ~3.000 tokens
    // (contenido + system prompt + respuesta), lo que permite 3-4 generaciones/minuto.
    // RIESGO: documentos largos quedan truncados. Aceptable para MVP.
    private static final int MAX_CHARS_TEXTO = 10_000;

    private final DocumentoRepository documentoRepository;
    private final MaterialGeneradoRepository materialRepository;
    private final UsuarioRepository usuarioRepository;
    private final ChatClient chatClient;
    private final ObjectMapper objectMapper;

    @Value("${app.uploads.path}")
    private String uploadsPath;

    // ─── Endpoints ────────────────────────────────────────────────────────────

    @Transactional
    public DocumentoResponse subirDocumento(String email, MultipartFile file) {
        validarArchivo(file);

        Usuario usuario = findUsuario(email);
        String tipoArchivo = resolverTipoArchivo(file.getOriginalFilename());
        byte[] bytes = leerBytes(file);

        // Persistir el archivo en disco
        String rutaFisica = guardarEnDisco(bytes, usuario.getId(), tipoArchivo);

        // Extraer texto
        String textoExtraido = extraerTexto(bytes, tipoArchivo, file.getOriginalFilename());

        Documento documento = Documento.builder()
                .usuario(usuario)
                .nombre(file.getOriginalFilename())
                .tipoArchivo(tipoArchivo)
                .rutaFisica(rutaFisica)
                .textoExtraido(textoExtraido)
                .tamanoBytes(file.getSize())
                .build();

        return toDocumentoResponse(documentoRepository.save(documento));
    }

    public List<DocumentoResponse> listarDocumentos(String email) {
        Long usuarioId = findUsuario(email).getId();
        return documentoRepository.findByUsuarioIdOrderByCreadoEnDesc(usuarioId)
                .stream()
                .map(this::toDocumentoResponse)
                .toList();
    }

    @Transactional
    public void eliminarDocumento(Long documentoId, String email) {
        Long usuarioId = findUsuario(email).getId();
        Documento documento = findDocumentoByOwner(documentoId, usuarioId);

        // Borrar el archivo físico (silencioso si no existe)
        try {
            Files.deleteIfExists(Paths.get(documento.getRutaFisica()));
        } catch (IOException e) {
            log.warn("No se pudo eliminar el archivo físico: {}", documento.getRutaFisica());
        }

        documentoRepository.delete(documento);
    }

    @Transactional
    public MaterialGeneradoResponse generarMaterial(Long documentoId, String email,
                                                     GenerarMaterialRequest request) {
        Long usuarioId = findUsuario(email).getId();
        Documento documento = findDocumentoByOwner(documentoId, usuarioId);

        if (documento.getTextoExtraido() == null || documento.getTextoExtraido().isBlank()) {
            throw new AppException(
                    "No se pudo extraer texto de este documento. Verifica que no sea un PDF escaneado.",
                    HttpStatus.UNPROCESSABLE_ENTITY);
        }

        String jsonGenerado = llamarIA(documento.getTextoExtraido(), request.getTipo());

        MaterialGenerado material = MaterialGenerado.builder()
                .documento(documento)
                .tipo(request.getTipo())
                .contenido(jsonGenerado)
                .build();

        return toMaterialResponse(materialRepository.save(material));
    }

    public List<MaterialGeneradoResponse> listarMateriales(Long documentoId, String email) {
        Long usuarioId = findUsuario(email).getId();
        findDocumentoByOwner(documentoId, usuarioId); // ownership check
        return materialRepository.findByDocumentoIdOrderByCreadoEnDesc(documentoId)
                .stream()
                .map(this::toMaterialResponse)
                .toList();
    }

    // ─── Extracción de texto ──────────────────────────────────────────────────

    private String extraerTexto(byte[] bytes, String tipoArchivo, String nombreOriginal) {
        try {
            String texto = switch (tipoArchivo) {
                case "PDF" -> extraerTextoPdf(bytes);
                case "TXT" -> new String(bytes, StandardCharsets.UTF_8);
                default -> throw new AppException("Tipo de archivo no soportado", HttpStatus.BAD_REQUEST);
            };

            if (texto == null || texto.isBlank()) {
                log.warn("Texto vacío extraído de: {}", nombreOriginal);
                return null;
            }

            return texto.length() > MAX_CHARS_TEXTO
                    ? texto.substring(0, MAX_CHARS_TEXTO)
                    : texto;

        } catch (AppException e) {
            throw e;
        } catch (Exception e) {
            log.error("Error extrayendo texto de {}: {}", nombreOriginal, e.getMessage());
            return null; // No bloqueamos la subida si falla la extracción
        }
    }

    private String extraerTextoPdf(byte[] bytes) throws IOException {
        try (PDDocument doc = Loader.loadPDF(bytes)) {
            PDFTextStripper stripper = new PDFTextStripper();
            return stripper.getText(doc);
        }
    }

    // ─── Generación con IA ────────────────────────────────────────────────────

    private String llamarIA(String textoDocumento, TipoMaterial tipo) {
        String systemPrompt = buildSystemPrompt(tipo);
        String userPrompt = "Documento a analizar:\n---\n" + textoDocumento + "\n---";

        String respuesta;
        try {
            respuesta = chatClient.prompt()
                    .messages(
                            new SystemMessage(systemPrompt),
                            new UserMessage(userPrompt))
                    .call()
                    .content();
        } catch (Exception e) {
            throw new AppException(
                    "El servicio de IA no está disponible. Inténtalo de nuevo.",
                    HttpStatus.SERVICE_UNAVAILABLE);
        }

        return extraerJson(respuesta, tipo);
    }

    private String buildSystemPrompt(TipoMaterial tipo) {
        return switch (tipo) {
            case FLASHCARDS -> """
                    Eres un experto en técnicas de estudio para oposiciones en España.
                    Crea entre 10 y 20 flashcards a partir del documento proporcionado.
                    Responde EXCLUSIVAMENTE con un JSON válido, sin texto adicional ni bloques de código markdown.
                    Formato exacto (sin saltos de línea innecesarios):
                    {"tarjetas":[{"pregunta":"...","respuesta":"..."}]}
                    Las preguntas deben ser claras y concretas. Las respuestas, concisas pero completas.
                    """;
            case RESUMEN -> """
                    Eres un experto en síntesis de contenido para oposiciones en España.
                    Crea un resumen estructurado del documento proporcionado.
                    Responde EXCLUSIVAMENTE con un JSON válido, sin texto adicional ni bloques de código markdown.
                    Formato exacto:
                    {"texto":"## Título\\n\\n### Puntos principales\\n\\n..."}
                    El valor de "texto" puede contener markdown (##, ###, -, **negrita**).
                    Usa el idioma del documento original.
                    """;
            case CONCEPTOS_CLAVE -> """
                    Eres un experto en extracción de conceptos para oposiciones en España.
                    Extrae entre 15 y 25 términos y conceptos clave del documento proporcionado.
                    Responde EXCLUSIVAMENTE con un JSON válido, sin texto adicional ni bloques de código markdown.
                    Formato exacto:
                    {"conceptos":[{"termino":"...","definicion":"..."}]}
                    Ordena los conceptos de más a menos importante.
                    """;
        };
    }

    /**
     * Extrae el JSON de la respuesta del LLM.
     * Los LLMs a veces envuelven la respuesta en bloques de código markdown (```json ... ```).
     * Este método limpia esa envoltura y valida que el resultado sea JSON válido.
     */
    private String extraerJson(String respuesta, TipoMaterial tipo) {
        String limpio = respuesta.strip();

        // Quitar bloque de código markdown si existe
        if (limpio.startsWith("```")) {
            int inicio = limpio.indexOf('\n');
            int fin = limpio.lastIndexOf("```");
            if (inicio != -1 && fin > inicio) {
                limpio = limpio.substring(inicio + 1, fin).strip();
            }
        }

        // Validar que es JSON parseable
        try {
            objectMapper.readTree(limpio);
            return limpio;
        } catch (JsonProcessingException e) {
            log.error("IA devolvió JSON inválido para tipo {}: {}", tipo, limpio);
            throw new AppException(
                    "La IA devolvió una respuesta con formato incorrecto. Inténtalo de nuevo.",
                    HttpStatus.BAD_GATEWAY);
        }
    }

    // ─── Almacenamiento físico ────────────────────────────────────────────────

    private String guardarEnDisco(byte[] bytes, Long usuarioId, String tipoArchivo) {
        try {
            Path dir = Paths.get(uploadsPath, "documentos", String.valueOf(usuarioId));
            Files.createDirectories(dir);

            String extension = tipoArchivo.equals("PDF") ? ".pdf" : ".txt";
            String filename = UUID.randomUUID() + extension;
            Path ruta = dir.resolve(filename);
            Files.write(ruta, bytes);

            return ruta.toString();
        } catch (IOException e) {
            throw new AppException("Error al guardar el archivo en disco.", HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // ─── Validaciones ─────────────────────────────────────────────────────────

    private void validarArchivo(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new AppException("El archivo está vacío.", HttpStatus.BAD_REQUEST);
        }
        String nombre = file.getOriginalFilename();
        if (nombre == null) {
            throw new AppException("El archivo no tiene nombre.", HttpStatus.BAD_REQUEST);
        }
        String lower = nombre.toLowerCase();
        if (!lower.endsWith(".pdf") && !lower.endsWith(".txt")) {
            throw new AppException("Solo se admiten archivos PDF y TXT.", HttpStatus.BAD_REQUEST);
        }
    }

    private String resolverTipoArchivo(String nombre) {
        if (nombre != null && nombre.toLowerCase().endsWith(".pdf")) return "PDF";
        return "TXT";
    }

    private byte[] leerBytes(MultipartFile file) {
        try {
            return file.getBytes();
        } catch (IOException e) {
            throw new AppException("Error al leer el archivo.", HttpStatus.BAD_REQUEST);
        }
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private Documento findDocumentoByOwner(Long documentoId, Long usuarioId) {
        return documentoRepository.findByIdAndUsuarioId(documentoId, usuarioId)
                .orElseThrow(() -> new AppException("Documento no encontrado.", HttpStatus.NOT_FOUND));
    }

    private Usuario findUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new AppException("Usuario no encontrado.", HttpStatus.NOT_FOUND));
    }

    // ─── Mapping ──────────────────────────────────────────────────────────────

    private DocumentoResponse toDocumentoResponse(Documento d) {
        return DocumentoResponse.builder()
                .id(d.getId())
                .nombre(d.getNombre())
                .tipoArchivo(d.getTipoArchivo())
                .tamanoBytes(d.getTamanoBytes())
                .textoDisponible(d.getTextoExtraido() != null && !d.getTextoExtraido().isBlank())
                .creadoEn(d.getCreadoEn())
                .build();
    }

    private MaterialGeneradoResponse toMaterialResponse(MaterialGenerado m) {
        JsonNode contenidoJson;
        try {
            contenidoJson = objectMapper.readTree(m.getContenido());
        } catch (JsonProcessingException e) {
            contenidoJson = objectMapper.createObjectNode();
        }

        return MaterialGeneradoResponse.builder()
                .id(m.getId())
                .documentoId(m.getDocumento().getId())
                .tipo(m.getTipo())
                .contenido(contenidoJson)
                .creadoEn(m.getCreadoEn())
                .build();
    }
}
