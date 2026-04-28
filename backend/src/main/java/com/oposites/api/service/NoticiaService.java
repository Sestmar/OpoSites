package com.oposites.api.service;

import com.oposites.api.exception.AppException;
import com.oposites.api.model.dto.request.CreateNoticiaRequest;
import com.oposites.api.model.dto.request.UpdateNoticiaRequest;
import com.oposites.api.model.dto.response.NoticiaResumenResponse;
import com.oposites.api.model.dto.response.NoticiaResponse;
import com.oposites.api.model.entity.NoticiaConvocatoria;
import com.oposites.api.model.entity.NoticiaLeida;
import com.oposites.api.model.entity.NoticiaLeidaId;
import com.oposites.api.model.entity.RamaOposicion;
import com.oposites.api.model.entity.Usuario;
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

    public Page<NoticiaResumenResponse> listarNoticias(String email, Long ramaId, TipoNoticia tipo, Pageable pageable) {
        Usuario usuario = findUsuario(email);
        Long efectivoRamaId = ramaId != null ? ramaId : usuario.getRamaPrincipalId();
        Set<Long> leidasIds = noticiaLeidaRepository.findNoticiaIdsByUsuarioId(usuario.getId());

        Page<NoticiaConvocatoria> page = efectivoRamaId != null
                ? noticiaRepository.findFiltered(efectivoRamaId, tipo, pageable)
                : noticiaRepository.findGlobalFiltered(tipo, pageable);

        return page.map(n -> toResumenResponse(n, leidasIds.contains(n.getId())));
    }

    public NoticiaResponse getDetalle(Long id, String email) {
        Usuario usuario = findUsuario(email);
        NoticiaConvocatoria noticia = noticiaRepository.findByIdAndActiveTrue(id)
                .orElseThrow(() -> new AppException("Noticia no encontrada", HttpStatus.NOT_FOUND));

        boolean leida = noticiaLeidaRepository.existsById(new NoticiaLeidaId(id, usuario.getId()));
        return toResponse(noticia, leida);
    }

    @Transactional
    public void marcarLeida(Long id, String email) {
        Usuario usuario = findUsuario(email);
        NoticiaConvocatoria noticia = noticiaRepository.findByIdAndActiveTrue(id)
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
                .build();
    }
}
