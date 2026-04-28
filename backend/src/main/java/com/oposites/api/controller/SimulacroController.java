package com.oposites.api.controller;

import com.oposites.api.model.dto.request.ResponderTestRequest;
import com.oposites.api.model.dto.response.ResultadoTestResponse;
import com.oposites.api.model.dto.response.SimulacroResponse;
import com.oposites.api.model.dto.response.TestIniciadoResponse;
import com.oposites.api.service.SimulacroService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Simulacros", description = "Simulacros oficiales por oposición: inicio, entrega y resultados")
@RestController
@RequestMapping("/api/v1/simulacros")
@RequiredArgsConstructor
public class SimulacroController {

    private final SimulacroService simulacroService;

    @GetMapping("/{id}")
    public ResponseEntity<SimulacroResponse> obtener(@PathVariable Long id) {
        return ResponseEntity.ok(simulacroService.obtenerPorId(id));
    }

    @PostMapping("/{id}/iniciar")
    public ResponseEntity<TestIniciadoResponse> iniciar(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long id) {
        return ResponseEntity.ok(simulacroService.iniciar(user.getUsername(), id));
    }

    @PostMapping("/{id}/entregar")
    public ResponseEntity<ResultadoTestResponse> entregar(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long id,
            @Valid @RequestBody ResponderTestRequest request) {
        return ResponseEntity.ok(simulacroService.entregar(user.getUsername(), id, request));
    }
}
