package com.oposites.api.service;

import com.oposites.api.exception.AppException;
import com.oposites.api.model.dto.request.CreateNoticiaRequest;
import com.oposites.api.model.dto.request.UpdateNoticiaRequest;
import com.oposites.api.model.dto.response.NoticiaConteosResponse;
import com.oposites.api.model.dto.response.NoticiaResumenResponse;
import com.oposites.api.model.dto.response.NoticiaResponse;
import com.oposites.api.model.entity.NoticiaConvocatoria;
import com.oposites.api.model.entity.NoticiaLeida;
import com.oposites.api.model.entity.NoticiaLeidaId;
import com.oposites.api.model.entity.RamaOposicion;
import com.oposites.api.model.entity.Usuario;
import com.oposites.api.model.enums.EstadoEditorialNoticia;
import com.oposites.api.model.enums.TipoNoticia;
import com.oposites.api.repository.NoticiaConvocatoriaRepository;
import com.oposites.api.repository.NoticiaLeidaRepository;
import com.oposites.api.repository.RamaOposicionRepository;
import com.oposites.api.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class NoticiaService {

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private final NoticiaConvocatoriaRepository noticiaRepository;
    private final NoticiaLeidaRepository noticiaLeidaRepository;
    private final UsuarioRepository usuarioRepository;
    private final RamaOposicionRepository ramaRepository;

    // ─── Endpoints USER ────────────────────────────────────────────────────────

    public Page<NoticiaResumenResponse> listarNoticias(String email, Long ramaId, TipoNoticia tipo, String q, Pageable pageable) {
        Usuario usuario = findUsuario(email);
        Set<Long> leidasIds = noticiaLeidaRepository.findNoticiaIdsByUsuarioId(usuario.getId());

        // q vacío o solo espacios → null (sin filtro)
        String efectivoQ = (q != null && !q.isBlank()) ? q.trim() : null;

        // ramaId null → "General": solo noticias globales (rama IS NULL).
        // ramaId = X   → noticias de esa rama + globales (n.rama.id = X OR n.rama IS NULL).
        // El frontend siempre envía el ramaId explícito del chip seleccionado; no hay fallback
        // a la rama principal del usuario para evitar inconsistencias con los conteos.
        Page<NoticiaConvocatoria> page = ramaId != null
                ? noticiaRepository.findFiltered(ramaId, tipo, EstadoEditorialNoticia.PUBLICADA, efectivoQ, pageable)
                : noticiaRepository.findGlobalFiltered(tipo, EstadoEditorialNoticia.PUBLICADA, efectivoQ, pageable);

        return page.map(n -> toResumenResponse(n, leidasIds.contains(n.getId())));
    }

    public NoticiaResponse getDetalle(Long id, String email) {
        Usuario usuario = findUsuario(email);
        NoticiaConvocatoria noticia = noticiaRepository
                .findByIdAndActiveTrueAndEstadoEditorial(id, EstadoEditorialNoticia.PUBLICADA)
                .orElseThrow(() -> new AppException("Noticia no encontrada", HttpStatus.NOT_FOUND));

        boolean leida = noticiaLeidaRepository.existsById(new NoticiaLeidaId(id, usuario.getId()));
        return toResponse(noticia, leida);
    }

    @Transactional
    public void marcarLeida(Long id, String email) {
        Usuario usuario = findUsuario(email);
        NoticiaConvocatoria noticia = noticiaRepository
                .findByIdAndActiveTrueAndEstadoEditorial(id, EstadoEditorialNoticia.PUBLICADA)
                .orElseThrow(() -> new AppException("Noticia no encontrada", HttpStatus.NOT_FOUND));

        NoticiaLeidaId leidaId = new NoticiaLeidaId(id, usuario.getId());
        if (!noticiaLeidaRepository.existsById(leidaId)) {
            noticiaLeidaRepository.save(NoticiaLeida.builder()
                    .id(leidaId)
                    .noticia(noticia)
                    .usuario(usuario)
                    .build());
        }
    }

    /**
     * Devuelve conteos por tipo coherentes con la query principal de /noticias.
     *
     * <ul>
     *   <li>ramaId = null  → "General": solo noticias con rama IS NULL (globales).
     *       Los conteos pueden ser altos porque la mayoría del BOE ingresa sin rama.
     *   <li>ramaId = X     → noticias de la rama X + globales (misma lógica que findFiltered).
     *       Los conteos suelen ser similares a "General" mientras pocas noticias tengan rama asignada.
     * </ul>
     *
     * No hay fallback a la rama principal del usuario: el frontend envía siempre el ramaId
     * explícito del chip seleccionado para garantizar coherencia entre lista y conteos.
     */
    public NoticiaConteosResponse getConteos(String email, Long ramaId) {
        Usuario usuario = findUsuario(email);

        long todas, convocatorias, cambios, noticias, leidas;
        if (ramaId != null) {
            // rama X + globales — misma lógica que findFiltered
            todas         = noticiaRepository.countFiltered(ramaId, EstadoEditorialNoticia.PUBLICADA, null);
            convocatorias = noticiaRepository.countFiltered(ramaId, EstadoEditorialNoticia.PUBLICADA, TipoNoticia.CONVOCATORIA);
            cambios       = noticiaRepository.countFiltered(ramaId, EstadoEditorialNoticia.PUBLICADA, TipoNoticia.CAMBIO);
            noticias      = noticiaRepository.countFiltered(ramaId, EstadoEditorialNoticia.PUBLICADA, TipoNoticia.NOTICIA);
            leidas        = noticiaLeidaRepository.countLeidasFiltradas(usuario.getId(), ramaId, EstadoEditorialNoticia.PUBLICADA);
        } else {
            // solo globales — misma lógica que findGlobalFiltered
            todas         = noticiaRepository.countGlobalFiltered(EstadoEditorialNoticia.PUBLICADA, null);
            convocatorias = noticiaRepository.countGlobalFiltered(EstadoEditorialNoticia.PUBLICADA, TipoNoticia.CONVOCATORIA);
            cambios       = noticiaRepository.countGlobalFiltered(EstadoEditorialNoticia.PUBLICADA, TipoNoticia.CAMBIO);
            noticias      = noticiaRepository.countGlobalFiltered(EstadoEditorialNoticia.PUBLICADA, TipoNoticia.NOTICIA);
            leidas        = noticiaLeidaRepository.countLeidasGlobal(usuario.getId(), EstadoEditorialNoticia.PUBLICADA);
        }

        long noLeidas = Math.max(0, todas - leidas);
        return new NoticiaConteosResponse(todas, convocatorias, cambios, noticias, noLeidas);
    }

    // ─── CRUD admin ────────────────────────────────────────────────────────────

    @Transactional
    public NoticiaResponse crear(CreateNoticiaRequest request) {
        RamaOposicion rama = resolveRama(request.getRamaId());

        NoticiaConvocatoria noticia = NoticiaConvocatoria.builder()
                .rama(rama)
                .titulo(request.getTitulo())
                .contenido(request.getContenido())
                .urlExterna(request.getUrlExterna())
                .tipo(request.getTipo())
                .fechaPublicacion(request.getFechaPublicacion())
                .estadoEditorial(EstadoEditorialNoticia.PUBLICADA)
                .build();

        return toResponse(noticiaRepository.save(noticia), false);
    }

    @Transactional
    public NoticiaResponse actualizar(Long id, UpdateNoticiaRequest request) {
        NoticiaConvocatoria noticia = noticiaRepository.findById(id)
                .orElseThrow(() -> new AppException("Noticia no encontrada", HttpStatus.NOT_FOUND));

        if (request.getTitulo() != null)           noticia.setTitulo(request.getTitulo());
        if (request.getContenido() != null)        noticia.setContenido(request.getContenido());
        if (request.getUrlExterna() != null)       noticia.setUrlExterna(request.getUrlExterna());
        if (request.getTipo() != null)             noticia.setTipo(request.getTipo());
        if (request.getFechaPublicacion() != null) noticia.setFechaPublicacion(request.getFechaPublicacion());
        if (request.getActive() != null)           noticia.setActive(request.getActive());

        return toResponse(noticiaRepository.save(noticia), false);
    }

    @Transactional
    public void eliminar(Long id) {
        if (!noticiaRepository.existsById(id)) {
            throw new AppException("Noticia no encontrada", HttpStatus.NOT_FOUND);
        }
        noticiaRepository.deleteById(id);
    }

    public Page<NoticiaResponse> listarBorradores(Pageable pageable) {
        return noticiaRepository
                .findByEstadoEditorialOrderByFechaPublicacionDesc(EstadoEditorialNoticia.BORRADOR, pageable)
                .map(n -> toResponse(n, false));
    }

    @Transactional
    public NoticiaResponse actualizarEstadoEditorial(Long id, EstadoEditorialNoticia estadoEditorial) {
        if (estadoEditorial == EstadoEditorialNoticia.BORRADOR) {
            throw new AppException("Estado no permitido para esta operación", HttpStatus.BAD_REQUEST);
        }

        NoticiaConvocatoria noticia = noticiaRepository.findById(id)
                .orElseThrow(() -> new AppException("Noticia no encontrada", HttpStatus.NOT_FOUND));
        noticia.setEstadoEditorial(estadoEditorial);
        return toResponse(noticiaRepository.save(noticia), false);
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private RamaOposicion resolveRama(Long ramaId) {
        if (ramaId == null) return null;
        return ramaRepository.findById(ramaId)
                .orElseThrow(() -> new AppException("Oposición no encontrada", HttpStatus.NOT_FOUND));
    }

    private Usuario findUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new AppException("Usuario no encontrado", HttpStatus.NOT_FOUND));
    }

    // ─── Mapping ──────────────────────────────────────────────────────────────

    private NoticiaResumenResponse toResumenResponse(NoticiaConvocatoria n, boolean leida) {
        return NoticiaResumenResponse.builder()
                .id(n.getId())
                .titulo(n.getTitulo())
                .tipo(n.getTipo())
                .ramaId(n.getRama() != null ? n.getRama().getId() : null)
                .nombreRama(n.getRama() != null ? n.getRama().getNombre() : null)
                .fechaPublicacion(n.getFechaPublicacion().format(FORMATTER))
                .leida(leida)
                .build();
    }

    private NoticiaResponse toResponse(NoticiaConvocatoria n, boolean leida) {
        return NoticiaResponse.builder()
                .id(n.getId())
                .titulo(n.getTitulo())
                .contenido(n.getContenido())
                .urlExterna(n.getUrlExterna())
                .tipo(n.getTipo())
                .ramaId(n.getRama() != null ? n.getRama().getId() : null)
                .nombreRama(n.getRama() != null ? n.getRama().getNombre() : null)
                .fechaPublicacion(n.getFechaPublicacion().format(FORMATTER))
                .leida(leida)
                .estadoEditorial(n.getEstadoEditorial())
                .build();
    }
}
