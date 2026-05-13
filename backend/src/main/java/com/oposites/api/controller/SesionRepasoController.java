package com.oposites.api.controller;

import com.oposites.api.model.dto.request.ResponderRepasoRequest;
import com.oposites.api.model.dto.response.IniciarSesionRepasoResponse;
import com.oposites.api.model.dto.response.ResponderRepasoResponse;
import com.oposites.api.model.dto.response.ResultadoSesionRepasoResponse;
import com.oposites.api.service.SesionRepasoService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Repaso", description = "Sesiones de repaso personalizado por fallos (5.2)")
@RestController
@RequestMapping("/api/v1/repaso")
@RequiredArgsConstructor
public class SesionRepasoController {

    private final SesionRepasoService sesionRepasoService;

    /** Inicia una nueva sesión de repaso generando 10 MCQ sobre los temas más débiles del usuario. */
    @PostMapping("/sesiones")
    public ResponseEntity<IniciarSesionRepasoResponse> iniciar(
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(sesionRepasoService.iniciar(user.getUsername()));
    }

    /** Registra la respuesta a una pregunta. Si es la última, completa la sesión automáticamente. */
    @PostMapping("/sesiones/{id}/respuestas")
    public ResponseEntity<ResponderRepasoResponse> responder(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long id,
            @Valid @RequestBody ResponderRepasoRequest request) {
        return ResponseEntity.ok(sesionRepasoService.responder(id, user.getUsername(), request));
    }

    /** Devuelve el resultado completo de una sesión (solo disponible cuando está COMPLETADA). */
    @GetMapping("/sesiones/{id}/resultado")
    public ResponseEntity<ResultadoSesionRepasoResponse> resultado(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long id) {
        return ResponseEntity.ok(sesionRepasoService.obtenerResultado(id, user.getUsername()));
    }
}
