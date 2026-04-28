package com.oposites.api.controller;

import com.oposites.api.model.dto.request.UpdatePerfilRequest;
import com.oposites.api.model.dto.request.UpdateRamaRequest;
import com.oposites.api.model.dto.response.UsuarioResponse;
import com.oposites.api.service.UsuarioService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/usuarios")
@RequiredArgsConstructor
public class UsuarioController {

    private final UsuarioService usuarioService;

    @GetMapping("/me")
    public ResponseEntity<UsuarioResponse> getPerfil(@AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(usuarioService.getPerfil(userDetails.getUsername()));
    }

    @PutMapping("/me")
    public ResponseEntity<UsuarioResponse> updatePerfil(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody UpdatePerfilRequest request) {
        return ResponseEntity.ok(usuarioService.updatePerfil(userDetails.getUsername(), request));
    }

    @PutMapping("/me/rama")
    public ResponseEntity<UsuarioResponse> updateRama(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody UpdateRamaRequest request) {
        return ResponseEntity.ok(usuarioService.updateRama(userDetails.getUsername(), request.getRamaId()));
    }

    @DeleteMapping("/me")
    public ResponseEntity<Void> deleteAccount(@AuthenticationPrincipal UserDetails userDetails) {
        usuarioService.deleteAccount(userDetails.getUsername());
        return ResponseEntity.noContent().build();
    }
}
