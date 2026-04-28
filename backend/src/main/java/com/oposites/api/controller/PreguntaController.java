package com.oposites.api.controller;

import com.oposites.api.model.dto.response.PreguntaResponse;
import com.oposites.api.model.dto.response.PreguntaRespuestaResponse;
import com.oposites.api.service.PreguntaService;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Preguntas", description = "Consulta de preguntas individuales y sus respuestas correctas")
@RestController
@RequestMapping("/api/v1/preguntas")
@RequiredArgsConstructor
public class PreguntaController {

    private final PreguntaService preguntaService;

    /** GET /api/v1/preguntas/{id} — devuelve pregunta SIN respuesta correcta */
    @GetMapping("/{id}")
    public ResponseEntity<PreguntaResponse> obtenerPorId(@PathVariable Long id) {
        return ResponseEntity.ok(preguntaService.obtenerPorId(id));
    }

    /**
     * GET /api/v1/preguntas/{id}/respuesta — devuelve respuesta + explicación.
     * En Fase 3 se añadirá validación de progreso (usuario ya respondió).
     */
    @GetMapping("/{id}/respuesta")
    public ResponseEntity<PreguntaRespuestaResponse> obtenerRespuesta(@PathVariable Long id) {
        return ResponseEntity.ok(preguntaService.obtenerRespuesta(id));
    }
}
