package com.oposites.api.controller;

import com.oposites.api.model.dto.request.CreatePreguntaRequest;
import com.oposites.api.model.dto.request.UpdatePreguntaRequest;
import com.oposites.api.model.dto.response.PreguntaResponse;
import com.oposites.api.service.PreguntaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminPreguntaController {

    private final PreguntaService preguntaService;

    @PostMapping("/temas/{temaId}/preguntas")
    public ResponseEntity<PreguntaResponse> crear(
            @PathVariable Long temaId,
            @Valid @RequestBody CreatePreguntaRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(preguntaService.crear(temaId, request));
    }

    @PutMapping("/preguntas/{id}")
    public ResponseEntity<PreguntaResponse> actualizar(
            @PathVariable Long id,
            @Valid @RequestBody UpdatePreguntaRequest request) {
        return ResponseEntity.ok(preguntaService.actualizar(id, request));
    }

    @DeleteMapping("/preguntas/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        preguntaService.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}
