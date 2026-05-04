package com.oposites.api.controller;

import com.oposites.api.model.dto.request.GenerarMaterialRequest;
import com.oposites.api.model.dto.response.DocumentoResponse;
import com.oposites.api.model.dto.response.MaterialGeneradoResponse;
import com.oposites.api.service.DocumentoService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@Tag(name = "Documentos", description = "Gestión de documentos personales y generación de materiales de estudio con IA")
@RestController
@RequestMapping("/api/v1/documentos")
@RequiredArgsConstructor
public class DocumentoController {

    private final DocumentoService documentoService;

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<DocumentoResponse> subirDocumento(
            @AuthenticationPrincipal UserDetails user,
            @RequestPart("file") MultipartFile file) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(documentoService.subirDocumento(user.getUsername(), file));
    }

    @GetMapping
    public ResponseEntity<List<DocumentoResponse>> listarDocumentos(
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(documentoService.listarDocumentos(user.getUsername()));
    }

    @DeleteMapping("/{documentoId}")
    public ResponseEntity<Void> eliminarDocumento(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long documentoId) {
        documentoService.eliminarDocumento(documentoId, user.getUsername());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{documentoId}/generar")
    public ResponseEntity<MaterialGeneradoResponse> generarMaterial(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long documentoId,
            @Valid @RequestBody GenerarMaterialRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(documentoService.generarMaterial(documentoId, user.getUsername(), request));
    }

    @GetMapping("/{documentoId}/materiales")
    public ResponseEntity<List<MaterialGeneradoResponse>> listarMateriales(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long documentoId) {
        return ResponseEntity.ok(documentoService.listarMateriales(documentoId, user.getUsername()));
    }
}
