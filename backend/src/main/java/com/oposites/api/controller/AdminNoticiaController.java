package com.oposites.api.controller;

import com.oposites.api.model.dto.request.CreateNoticiaRequest;
import com.oposites.api.model.dto.request.UpdateNoticiaRequest;
import com.oposites.api.model.dto.response.NoticiaResponse;
import com.oposites.api.service.NoticiaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/noticias")
@RequiredArgsConstructor
public class AdminNoticiaController {

    private final NoticiaService noticiaService;

    @PostMapping
    public ResponseEntity<NoticiaResponse> crear(@Valid @RequestBody CreateNoticiaRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(noticiaService.crear(request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<NoticiaResponse> actualizar(
            @PathVariable Long id,
            @RequestBody UpdateNoticiaRequest request) {
        return ResponseEntity.ok(noticiaService.actualizar(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        noticiaService.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}
