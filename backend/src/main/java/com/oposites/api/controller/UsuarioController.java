package com.oposites.api.controller;

import com.oposites.api.model.dto.request.UpdatePerfilRequest;
import com.oposites.api.model.dto.request.UpdateRamaRequest;
import com.oposites.api.model.dto.response.UsuarioResponse;
import com.oposites.api.service.FileStorageService;
import com.oposites.api.service.UsuarioService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.net.MalformedURLException;
import java.nio.file.Path;

@Tag(name = "Usuarios", description = "Perfil del usuario autenticado: consulta, edición y baja")
@RestController
@RequestMapping("/api/v1/usuarios")
@RequiredArgsConstructor
public class UsuarioController {

    private final UsuarioService usuarioService;
    private final FileStorageService fileStorageService;

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

    @PostMapping(value = "/me/foto", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<UsuarioResponse> uploadFoto(
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(usuarioService.uploadFoto(userDetails.getUsername(), file));
    }

    @GetMapping("/fotos/{filename:.+}")
    public ResponseEntity<Resource> serveFile(@PathVariable String filename) {
        try {
            Path filePath = fileStorageService.resolve("fotos-perfil", filename);
            Resource resource = new UrlResource(filePath.toUri());
            if (!resource.exists() || !resource.isReadable()) {
                return ResponseEntity.notFound().build();
            }
            String contentType = determineContentType(filename);
            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(contentType))
                    .body(resource);
        } catch (MalformedURLException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @DeleteMapping("/me")
    public ResponseEntity<Void> deleteAccount(@AuthenticationPrincipal UserDetails userDetails) {
        usuarioService.deleteAccount(userDetails.getUsername());
        return ResponseEntity.noContent().build();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers privados
    // ─────────────────────────────────────────────────────────────────────────

    private String determineContentType(String filename) {
        String lower = filename.toLowerCase();
        if (lower.endsWith(".png"))  return "image/png";
        if (lower.endsWith(".gif"))  return "image/gif";
        if (lower.endsWith(".webp")) return "image/webp";
        if (lower.endsWith(".svg"))  return "image/svg+xml";
        return "image/jpeg";
    }
}
