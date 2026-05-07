package com.oposites.api.service;

import com.oposites.api.model.entity.FuenteNoticia;
import com.oposites.api.model.entity.NoticiaConvocatoria;
import com.oposites.api.model.enums.EstadoEditorialNoticia;
import com.oposites.api.model.enums.TipoNoticia;
import com.oposites.api.repository.FuenteNoticiaRepository;
import com.oposites.api.repository.NoticiaConvocatoriaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClient;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

import javax.xml.parsers.DocumentBuilderFactory;
import java.io.StringReader;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class NoticiaIngestionService {
    // MVP: no caducidad automática de BORRADOR.
    // La gestión de borradores antiguos se realiza desde endpoints admin
    // (listar borradores + PATCH de estado a PUBLICADA/RECHAZADA).

    private final FuenteNoticiaRepository fuenteNoticiaRepository;
    private final NoticiaConvocatoriaRepository noticiaRepository;
    private final RestClient restClient;

    @Scheduled(cron = "${app.noticias.ingesta.cron:0 0 */6 * * *}")
    @Transactional
    public void ejecutarIngestaProgramada() {
        IngestionResult result = ejecutarIngesta();
        log.info("Ingesta noticias completada: fuentes={}, leidos={}, creados={}, duplicados={}, errores={}",
                result.fuentesProcesadas(), result.itemsLeidos(), result.itemsCreados(), result.itemsDuplicados(), result.errores());
    }

    @Transactional
    public IngestionResult ejecutarIngesta() {
        List<FuenteNoticia> fuentes = fuenteNoticiaRepository.findByActivaTrueOrderByIdAsc();
        Set<String> dedupeKeysLote = new HashSet<>();

        int itemsLeidos = 0;
        int itemsCreados = 0;
        int itemsDuplicados = 0;
        int itemsFiltrados = 0;
        int errores = 0;

        for (FuenteNoticia fuente : fuentes) {
            try {
                List<IngestedItem> items = switch (fuente.getTipoFuente()) {
                    case DUMMY -> readDummyItems(fuente);
                    case RSS -> readRssItems(fuente);
                    case API, SCRAPING -> Collections.emptyList();
                };
                itemsLeidos += items.size();

                for (IngestedItem item : items) {
                    // Filtro de relevancia: solo artículos de oposiciones.
                    // Las fuentes DUMMY se excluyen del filtro (son de prueba).
                    if (fuente.getTipoFuente() != com.oposites.api.model.enums.TipoFuente.DUMMY
                            && !esRelevanteParaOposiciones(item)) {
                        itemsFiltrados++;
                        continue;
                    }

                    // Dedupe en memoria para la ejecución actual:
                    // prioriza URL+fecha, y si no hay URL válida usa título+fecha.
                    String dedupeKey = buildDedupeKey(item);
                    if (!dedupeKeysLote.add(dedupeKey)) {
                        itemsDuplicados++;
                        continue;
                    }
                    if (isDuplicatedInDatabase(item)) {
                        itemsDuplicados++;
                        continue;
                    }

                    noticiaRepository.save(NoticiaConvocatoria.builder()
                            .rama(fuente.getRama())
                            .titulo(item.titulo())
                            .contenido(item.contenido())
                            .urlExterna(item.urlExterna())
                            .tipo(clasificarTipo(item))
                            .fechaPublicacion(item.fechaPublicacion())
                            .estadoEditorial(EstadoEditorialNoticia.BORRADOR)
                            .active(true)
                            .build());
                    itemsCreados++;
                }
            } catch (Exception e) {
                errores++;
                log.warn("Error procesando fuente id={} nombre={}: {}", fuente.getId(), fuente.getNombre(), e.getMessage());
            }
        }

        return new IngestionResult(
                fuentes.size(),
                itemsLeidos,
                itemsCreados,
                itemsDuplicados,
                itemsFiltrados,
                errores
        );
    }

    /**
     * Descarta artículos del BOE que no sean convocatorias de oposición.
     *
     * Lógica:
     *  1. Si el título contiene algún término de EXCLUSIÓN → false (ruido editorial).
     *  2. Si el título contiene algún término de INCLUSIÓN → true (relevante).
     *  3. Si no encaja en ninguno → false (descartado por defecto).
     *
     * Los términos están en minúsculas; la comparación ignora acentos y mayúsculas
     * mediante toLowerCase(). No se usa normalización Unicode para mantener la
     * dependencia en cero librerías externas.
     */
    private boolean esRelevanteParaOposiciones(IngestedItem item) {
        String texto = (item.titulo() + " " + (item.contenido() == null ? "" : item.contenido()))
                .toLowerCase(Locale.ROOT);

        // ── Exclusiones (traslados, comisiones, etc. — no interesan al opositor) ──
        if (containsAny(texto,
                "concurso de traslado",
                "comision de servicio",
                "comisión de servicio",
                "permuta",
                "excedencia",
                "jubilacion",
                "jubilación",
                "pension",
                "pensión",
                "incapacidad",
                "reconocimiento de trienios")) {
            return false;
        }

        // ── Inclusiones (artículos directamente sobre oposiciones) ──
        return containsAny(texto,
                "convocatoria",
                "proceso selectivo",
                "oposicion",
                "oposición",
                "prueba selectiva",
                "pruebas selectivas",
                "oferta de empleo",
                "acceso libre",
                "ingreso al cuerpo",
                "plazas de nuevo ingreso",
                "seleccion de personal",
                "selección de personal",
                "libre concurrencia");
    }

    private boolean isDuplicatedInDatabase(IngestedItem item) {
        // Regla de duplicado en BD:
        // 1) si existe URL, se evalúa URL(normalizada)+fecha_publicacion.
        // 2) fallback: título(normalizado)+fecha_publicacion.
        if (item.urlExterna() != null && !item.urlExterna().isBlank()) {
            if (noticiaRepository.existsByUrlAndFechaPublicacion(item.urlExterna().trim(), item.fechaPublicacion())) {
                return true;
            }
        }
        return noticiaRepository.existsByTituloAndFechaPublicacion(item.titulo().trim(), item.fechaPublicacion());
    }

    private String buildDedupeKey(IngestedItem item) {
        String fecha = item.fechaPublicacion().toString();
        String url = item.urlExterna() == null ? "" : item.urlExterna().trim().toLowerCase(Locale.ROOT);
        if (!url.isBlank()) {
            return "URL|" + url + "|" + fecha;
        }
        return "TITLE|" + item.titulo().trim().toLowerCase(Locale.ROOT) + "|" + fecha;
    }

    private TipoNoticia clasificarTipo(IngestedItem item) {
        String text = (item.titulo() + " " + item.contenido()).toLowerCase(Locale.ROOT);
        if (containsAny(text, "convocatoria", "plazas", "oferta de empleo", "oposición", "bases")) {
            return TipoNoticia.CONVOCATORIA;
        }
        if (containsAny(text, "cambio", "modificación", "corrección", "rectificación", "actualización")) {
            return TipoNoticia.CAMBIO;
        }
        return TipoNoticia.NOTICIA;
    }

    private boolean containsAny(String text, String... words) {
        for (String word : words) {
            if (text.contains(word)) {
                return true;
            }
        }
        return false;
    }

    private List<IngestedItem> readDummyItems(FuenteNoticia fuente) {
        LocalDate today = LocalDate.now();
        String safeBaseUrl = normalizeBaseUrl(fuente.getUrl());
        return List.of(
                new IngestedItem(
                        "[DUMMY] Nueva convocatoria " + fuente.getNombre(),
                        "Se detecta publicación de convocatoria en fuente " + fuente.getNombre(),
                        safeBaseUrl + "/convocatoria-" + today,
                        today.atTime(9, 0)
                ),
                new IngestedItem(
                        "[DUMMY] Cambio en bases " + fuente.getNombre(),
                        "Se detecta cambio en requisitos o fechas en " + fuente.getNombre(),
                        safeBaseUrl + "/cambio-" + today,
                        today.atTime(13, 0)
                )
        );
    }

    private List<IngestedItem> readRssItems(FuenteNoticia fuente) {
        String xml = restClient
                .get()
                .uri(fuente.getUrl())
                .retrieve()
                .body(String.class);

        if (xml == null || xml.isBlank()) {
            return Collections.emptyList();
        }

        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        disableExternalEntities(factory);

        try {
            Document doc = factory.newDocumentBuilder().parse(new InputSource(new StringReader(xml)));
            NodeList nodes = doc.getElementsByTagName("item");
            List<IngestedItem> items = new ArrayList<>();

            for (int i = 0; i < nodes.getLength(); i++) {
                Element item = (Element) nodes.item(i);
                String titulo = textContent(item, "title");
                if (titulo == null || titulo.isBlank()) {
                    continue;
                }
                String link = textContent(item, "link");
                String descripcion = textContent(item, "description");
                String pubDate = textContent(item, "pubDate");

                items.add(new IngestedItem(
                        titulo.trim(),
                        (descripcion == null || descripcion.isBlank())
                                ? "Contenido importado automáticamente desde RSS"
                                : descripcion.trim(),
                        (link == null || link.isBlank()) ? null : link.trim(),
                        parseDate(pubDate)
                ));
            }
            return items;
        } catch (Exception e) {
            throw new IllegalStateException("No se pudo parsear RSS", e);
        }
    }

    private void disableExternalEntities(DocumentBuilderFactory factory) {
        try {
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
            factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            factory.setXIncludeAware(false);
            factory.setExpandEntityReferences(false);
        } catch (Exception ignored) {
            // Si la JVM no soporta alguna feature, seguimos con defaults.
        }
    }

    private String textContent(Element parent, String tag) {
        NodeList list = parent.getElementsByTagName(tag);
        if (list.getLength() == 0) {
            return null;
        }
        return list.item(0).getTextContent();
    }

    private LocalDateTime parseDate(String value) {
        if (value == null || value.isBlank()) {
            return LocalDateTime.now();
        }
        try {
            return OffsetDateTime.parse(value).toLocalDateTime();
        } catch (Exception ignored) {
        }
        try {
            return ZonedDateTime.parse(value, DateTimeFormatter.RFC_1123_DATE_TIME).toLocalDateTime();
        } catch (Exception ignored) {
        }
        return LocalDateTime.now(ZoneOffset.UTC);
    }

    private String normalizeBaseUrl(String url) {
        if (url == null || url.isBlank()) {
            return "https://dummy.local";
        }
        return url.endsWith("/") ? url.substring(0, url.length() - 1) : url;
    }

    public record IngestedItem(
            String titulo,
            String contenido,
            String urlExterna,
            LocalDateTime fechaPublicacion
    ) {
    }

    public record IngestionResult(
            int fuentesProcesadas,
            int itemsLeidos,
            int itemsCreados,
            int itemsDuplicados,
            int itemsFiltrados,
            int errores
    ) {
    }
}
