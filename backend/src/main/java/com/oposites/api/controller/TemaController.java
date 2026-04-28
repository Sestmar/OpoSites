package com.oposites.api.controller;

import com.oposites.api.model.dto.response.PreguntaResponse;
import com.oposites.api.model.dto.response.TemaResponse;
import com.oposites.api.model.enums.TipoPregunta;
import com.oposites.api.service.PreguntaService;
import com.oposites.api.service.TemaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/temas")
@RequiredArgsConstructor
public class TemaController {

    private final TemaService temaService;
    private final PreguntaService preguntaService;

    /** GET /api/v1/temas/{id} — público */
    @GetMapping("/{id}")
    public ResponseEntity<TemaResponse> obtenerPorId(@PathVariable Long id) {
        return ResponseEntity.ok(temaService.obtenerPorId(id));
    }

    /**
     * GET /api/v1/temas/{temaId}/preguntas — requiere USER.
     * Filtros opcionales: tipo (MCQ|TRUE_FALSE|DESARROLLO), dificultad (1-5), limit (default 20).
     */
    @GetMapping("/{temaId}/preguntas")
    public ResponseEntity<List<PreguntaResponse>> listarPreguntas(
            @PathVariable Long temaId,
            @RequestParam(required = false) TipoPregunta tipo,
            @RequestParam(required = false) Integer dificultad,
            @RequestParam(defaultValue = "20") int limit) {
        return ResponseEntity.ok(preguntaService.listarPorTema(temaId, tipo, dificultad, limit));
    }
}
