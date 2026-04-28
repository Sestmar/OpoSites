package com.oposites.api.controller;

import com.oposites.api.model.dto.request.CreateTemaRequest;
import com.oposites.api.model.dto.request.UpdateTemaRequest;
import com.oposites.api.model.dto.response.TemaResponse;
import com.oposites.api.service.TemaService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Temas", description = "Temas de estudio por oposición y sus preguntas")
@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminTemaController {

    private final TemaService temaService;

    @PostMapping("/oposiciones/{ramaId}/temas")
    public ResponseEntity<TemaResponse> crear(
            @PathVariable Long ramaId,
            @Valid @RequestBody CreateTemaRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(temaService.crear(ramaId, request));
    }

    @PutMapping("/temas/{id}")
    public ResponseEntity<TemaResponse> actualizar(
            @PathVariable Long id,
            @RequestBody UpdateTemaRequest request) {
        return ResponseEntity.ok(temaService.actualizar(id, request));
    }

    @DeleteMapping("/temas/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        temaService.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}
