package com.oposites.api.controller;

import com.oposites.api.model.dto.response.DocumentoTestResponse;
import com.oposites.api.service.DocumentoTestService;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Documento Tests", description = "Tests MCQ generados desde documentos del usuario")
@RestController
@RequestMapping("/api/v1/documentos/{documentoId}/test")
@RequiredArgsConstructor
public class DocumentoTestController {

    private final DocumentoTestService documentoTestService;

    /** Genera (o regenera) un test MCQ a partir del documento. */
    @PostMapping("/generar")
    public ResponseEntity<DocumentoTestResponse> generar(
            @PathVariable Long documentoId,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(
                documentoTestService.generarTest(documentoId, userDetails.getUsername()));
    }

    /** Devuelve el último test generado para este documento. */
    @GetMapping("/ultimo")
    public ResponseEntity<DocumentoTestResponse> ultimo(
            @PathVariable Long documentoId,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(
                documentoTestService.obtenerUltimo(documentoId, userDetails.getUsername()));
    }

    /** Devuelve un test concreto por id. */
    @GetMapping("/{testId}")
    public ResponseEntity<DocumentoTestResponse> porId(
            @PathVariable Long documentoId,
            @PathVariable Long testId,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(
                documentoTestService.obtenerPorId(documentoId, testId, userDetails.getUsername()));
    }
}
