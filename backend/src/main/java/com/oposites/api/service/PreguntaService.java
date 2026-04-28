package com.oposites.api.service;

import com.oposites.api.exception.AppException;
import com.oposites.api.model.dto.request.CreatePreguntaRequest;
import com.oposites.api.model.dto.request.UpdatePreguntaRequest;
import com.oposites.api.model.dto.response.PreguntaResponse;
import com.oposites.api.model.dto.response.PreguntaRespuestaResponse;
import com.oposites.api.model.entity.Pregunta;
import com.oposites.api.model.entity.Tema;
import com.oposites.api.model.enums.TipoPregunta;
import com.oposites.api.repository.PreguntaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PreguntaService {

    private final PreguntaRepository preguntaRepository;
    private final TemaService temaService;

    // ─── Lectura (USER) ────────────────────────────────────────────────────────

    public List<PreguntaResponse> listarPorTema(Long temaId, TipoPregunta tipo, Integer dificultad, int limit) {
        // Valida que el tema exista
        temaService.findById(temaId);

        int pageSize = (limit > 0 && limit <= 200) ? limit : 20;
        return preguntaRepository
                .findByTemaIdWithFilters(temaId, tipo, dificultad, PageRequest.of(0, pageSize))
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public PreguntaResponse obtenerPorId(Long id) {
        return toResponse(findById(id));
    }

    /**
     * Devuelve respuesta + explicación.
     * En Fase 3 se añadirá validación de que el usuario ya respondió esta pregunta.
     */
    public PreguntaRespuestaResponse obtenerRespuesta(Long id) {
        Pregunta pregunta = findById(id);
        return PreguntaRespuestaResponse.builder()
                .preguntaId(pregunta.getId())
                .respuestaCorrecta(pregunta.getRespuestaCorrecta())
                .explicacion(pregunta.getExplicacion())
                .build();
    }

    // ─── CRUD admin ────────────────────────────────────────────────────────────

    @Transactional
    public PreguntaResponse crear(Long temaId, CreatePreguntaRequest request) {
        Tema tema = temaService.findById(temaId);

        Pregunta pregunta = Pregunta.builder()
                .tema(tema)
                .enunciado(request.getEnunciado())
                .tipo(request.getTipo())
                .opciones(request.getOpciones())
                .respuestaCorrecta(request.getRespuestaCorrecta())
                .explicacion(request.getExplicacion())
                .dificultad(request.getDificultad())
                .build();

        preguntaRepository.save(pregunta);
        temaService.incrementarPreguntasCount(tema);

        return toResponse(pregunta);
    }

    @Transactional
    public PreguntaResponse actualizar(Long id, UpdatePreguntaRequest request) {
        Pregunta pregunta = findById(id);

        if (request.getEnunciado() != null)        pregunta.setEnunciado(request.getEnunciado());
        if (request.getTipo() != null)             pregunta.setTipo(request.getTipo());
        if (request.getOpciones() != null)         pregunta.setOpciones(request.getOpciones());
        if (request.getRespuestaCorrecta() != null) pregunta.setRespuestaCorrecta(request.getRespuestaCorrecta());
        if (request.getExplicacion() != null)      pregunta.setExplicacion(request.getExplicacion());
        if (request.getDificultad() != null)       pregunta.setDificultad(request.getDificultad());

        return toResponse(preguntaRepository.save(pregunta));
    }

    @Transactional
    public void eliminar(Long id) {
        Pregunta pregunta = findById(id);
        Tema tema = pregunta.getTema();
        preguntaRepository.delete(pregunta);
        temaService.decrementarPreguntasCount(tema);
    }

    // ─── Helpers internos ─────────────────────────────────────────────────────

    private Pregunta findById(Long id) {
        return preguntaRepository.findById(id)
                .orElseThrow(() -> new AppException("Pregunta no encontrada", HttpStatus.NOT_FOUND));
    }

    // ─── Mapping ───────────────────────────────────────────────────────────────

    private PreguntaResponse toResponse(Pregunta p) {
        return PreguntaResponse.builder()
                .id(p.getId())
                .temaId(p.getTema().getId())
                .enunciado(p.getEnunciado())
                .tipo(p.getTipo())
                .opciones(p.getOpciones())
                .dificultad(p.getDificultad())
                .build();
    }
}
