package com.oposites.api.service;

import com.oposites.api.exception.AppException;
import com.oposites.api.model.dto.request.CreateRamaOposicionRequest;
import com.oposites.api.model.dto.request.UpdateRamaOposicionRequest;
import com.oposites.api.model.dto.response.RamaResponse;
import com.oposites.api.model.entity.RamaOposicion;
import com.oposites.api.repository.RamaOposicionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class RamaOposicionService {

    private final RamaOposicionRepository ramaRepository;

    // ─── Lectura pública ───────────────────────────────────────────────────────

    public List<RamaResponse> listarActivas() {
        return ramaRepository.findByActiveTrueOrderByNombre()
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public RamaResponse obtenerPorId(Long id) {
        return ramaRepository.findByIdAndActiveTrue(id)
                .map(this::toResponse)
                .orElseThrow(() -> new AppException("Oposición no encontrada", HttpStatus.NOT_FOUND));
    }

    // ─── CRUD admin ────────────────────────────────────────────────────────────

    @Transactional
    public RamaResponse crear(CreateRamaOposicionRequest request) {
        RamaOposicion rama = RamaOposicion.builder()
                .nombre(request.getNombre())
                .temarioOficialUrl(request.getTemarioOficialUrl())
                .build();
        return toResponse(ramaRepository.save(rama));
    }

    @Transactional
    public RamaResponse actualizar(Long id, UpdateRamaOposicionRequest request) {
        RamaOposicion rama = findById(id);

        if (request.getNombre() != null)          rama.setNombre(request.getNombre());
        if (request.getTemarioOficialUrl() != null) rama.setTemarioOficialUrl(request.getTemarioOficialUrl());
        if (request.getActive() != null)           rama.setActive(request.getActive());

        return toResponse(ramaRepository.save(rama));
    }

    /**
     * Soft delete: marca active=false.
     * Los usuarios que tenían esta rama como principal conservan el FK (ON DELETE SET NULL lo limpiará si se borra físicamente, pero eso no ocurre aquí).
     */
    @Transactional
    public void desactivar(Long id) {
        RamaOposicion rama = findById(id);
        rama.setActive(false);
        ramaRepository.save(rama);
    }

    // ─── Helpers internos (usados desde TemaService) ───────────────────────────

    public RamaOposicion findById(Long id) {
        return ramaRepository.findById(id)
                .orElseThrow(() -> new AppException("Oposición no encontrada", HttpStatus.NOT_FOUND));
    }

    public void incrementarTemasCount(RamaOposicion rama) {
        rama.setTemasCount(rama.getTemasCount() + 1);
        ramaRepository.save(rama);
    }

    public void decrementarTemasCount(RamaOposicion rama) {
        rama.setTemasCount(Math.max(0, rama.getTemasCount() - 1));
        ramaRepository.save(rama);
    }

    // ─── Mapping ───────────────────────────────────────────────────────────────

    private RamaResponse toResponse(RamaOposicion r) {
        return RamaResponse.builder()
                .id(r.getId())
                .nombre(r.getNombre())
                .temarioOficialUrl(r.getTemarioOficialUrl())
                .temasCount(r.getTemasCount())
                .active(r.isActive())
                .build();
    }
}
