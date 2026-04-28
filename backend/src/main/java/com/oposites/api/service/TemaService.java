package com.oposites.api.service;

import com.oposites.api.exception.AppException;
import com.oposites.api.model.dto.request.CreateTemaRequest;
import com.oposites.api.model.dto.request.UpdateTemaRequest;
import com.oposites.api.model.dto.response.TemaResponse;
import com.oposites.api.model.entity.RamaOposicion;
import com.oposites.api.model.entity.Tema;
import com.oposites.api.repository.TemaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TemaService {

    private final TemaRepository temaRepository;
    private final RamaOposicionService ramaService;

    // ─── Lectura pública ───────────────────────────────────────────────────────

    public List<TemaResponse> listarPorRama(Long ramaId) {
        // Valida que la rama exista y esté activa antes de listar temas
        ramaService.obtenerPorId(ramaId);
        return temaRepository.findByRamaIdOrderByOrden(ramaId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public TemaResponse obtenerPorId(Long id) {
        return toResponse(findById(id));
    }

    // ─── CRUD admin ────────────────────────────────────────────────────────────

    @Transactional
    public TemaResponse crear(Long ramaId, CreateTemaRequest request) {
        RamaOposicion rama = ramaService.findById(ramaId);

        Tema tema = Tema.builder()
                .rama(rama)
                .nombre(request.getNombre())
                .orden(request.getOrden())
                .descripcionCorta(request.getDescripcionCorta())
                .build();

        temaRepository.save(tema);
        ramaService.incrementarTemasCount(rama);

        return toResponse(tema);
    }

    @Transactional
    public TemaResponse actualizar(Long id, UpdateTemaRequest request) {
        Tema tema = findById(id);

        if (request.getNombre() != null)         tema.setNombre(request.getNombre());
        if (request.getOrden() != null)          tema.setOrden(request.getOrden());
        if (request.getDescripcionCorta() != null) tema.setDescripcionCorta(request.getDescripcionCorta());

        return toResponse(temaRepository.save(tema));
    }

    @Transactional
    public void eliminar(Long id) {
        Tema tema = findById(id);
        RamaOposicion rama = tema.getRama();
        temaRepository.delete(tema);
        ramaService.decrementarTemasCount(rama);
    }

    // ─── Helpers internos (usados desde PreguntaService) ──────────────────────

    public Tema findById(Long id) {
        return temaRepository.findById(id)
                .orElseThrow(() -> new AppException("Tema no encontrado", HttpStatus.NOT_FOUND));
    }

    public void incrementarPreguntasCount(Tema tema) {
        tema.setPreguntasCount(tema.getPreguntasCount() + 1);
        temaRepository.save(tema);
    }

    public void decrementarPreguntasCount(Tema tema) {
        tema.setPreguntasCount(Math.max(0, tema.getPreguntasCount() - 1));
        temaRepository.save(tema);
    }

    // ─── Mapping ───────────────────────────────────────────────────────────────

    private TemaResponse toResponse(Tema t) {
        return TemaResponse.builder()
                .id(t.getId())
                .ramaId(t.getRama().getId())
                .nombre(t.getNombre())
                .orden(t.getOrden())
                .descripcionCorta(t.getDescripcionCorta())
                .preguntasCount(t.getPreguntasCount())
                .build();
    }
}
