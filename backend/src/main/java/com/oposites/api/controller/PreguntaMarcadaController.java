package com.oposites.api.controller;

import com.oposites.api.model.dto.response.PreguntasMarcadasConteoResponse;
import com.oposites.api.service.PreguntaMarcadaService;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Preguntas Marcadas", description = "Marcar/desmarcar preguntas para repaso posterior")
@RestController
@RequestMapping("/api/v1/preguntas")
@RequiredArgsConstructor
public class PreguntaMarcadaController {

    private final PreguntaMarcadaService marcadaService;

    @PostMapping("/{id}/marcar")
    public ResponseEntity<Void> marcar(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long id) {
        marcadaService.marcar(user.getUsername(), id);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{id}/marcar")
    public ResponseEntity<Void> desmarcar(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long id) {
        marcadaService.desmarcar(user.getUsername(), id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/marcadas/conteo")
    public ResponseEntity<PreguntasMarcadasConteoResponse> conteo(
            @AuthenticationPrincipal UserDetails user,
            @RequestParam(required = false) Long ramaId) {
        return ResponseEntity.ok(marcadaService.getConteo(user.getUsername(), ramaId));
    }
}
