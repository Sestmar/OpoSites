package com.oposites.api.controller;

import com.oposites.api.model.dto.request.CreateSimulacroRequest;
import com.oposites.api.model.dto.request.UpdateSimulacroRequest;
import com.oposites.api.model.dto.response.SimulacroResponse;
import com.oposites.api.service.SimulacroService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminSimulacroController {

    private final SimulacroService simulacroService;

    @PostMapping("/oposiciones/{ramaId}/simulacros")
    public ResponseEntity<SimulacroResponse> crear(
            @PathVariable Long ramaId,
            @Valid @RequestBody CreateSimulacroRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(simulacroService.crear(ramaId, request));
    }

    @PutMapping("/simulacros/{id}")
    public ResponseEntity<SimulacroResponse> actualizar(
            @PathVariable Long id,
            @Valid @RequestBody UpdateSimulacroRequest request) {
        return ResponseEntity.ok(simulacroService.actualizar(id, request));
    }

    @DeleteMapping("/simulacros/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        simulacroService.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}
