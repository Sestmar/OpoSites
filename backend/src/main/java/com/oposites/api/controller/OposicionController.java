package com.oposites.api.controller;

import com.oposites.api.model.dto.response.RamaResponse;
import com.oposites.api.model.dto.response.SimulacroResponse;
import com.oposites.api.model.dto.response.TemaResponse;
import com.oposites.api.service.RamaOposicionService;
import com.oposites.api.service.SimulacroService;
import com.oposites.api.service.TemaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Endpoints públicos de ramas de oposición y sus temas.
 * Rutas GET marcadas como permitAll en SecurityConfig.
 */
@RestController
@RequestMapping("/api/v1/oposiciones")
@RequiredArgsConstructor
public class OposicionController {

    private final RamaOposicionService ramaService;
    private final TemaService temaService;
    private final SimulacroService simulacroService;

    @GetMapping
    public ResponseEntity<List<RamaResponse>> listarActivas() {
        return ResponseEntity.ok(ramaService.listarActivas());
    }

    @GetMapping("/{id}")
    public ResponseEntity<RamaResponse> obtenerPorId(@PathVariable Long id) {
        return ResponseEntity.ok(ramaService.obtenerPorId(id));
    }

    @GetMapping("/{ramaId}/temas")
    public ResponseEntity<List<TemaResponse>> listarTemasPorRama(@PathVariable Long ramaId) {
        return ResponseEntity.ok(temaService.listarPorRama(ramaId));
    }

    @GetMapping("/{ramaId}/simulacros")
    public ResponseEntity<List<SimulacroResponse>> listarSimulacros(@PathVariable Long ramaId) {
        return ResponseEntity.ok(simulacroService.listarPorRama(ramaId));
    }
}
