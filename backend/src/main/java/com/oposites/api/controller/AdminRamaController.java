package com.oposites.api.controller;

import com.oposites.api.model.dto.request.CreateRamaOposicionRequest;
import com.oposites.api.model.dto.request.UpdateRamaOposicionRequest;
import com.oposites.api.model.dto.response.RamaResponse;
import com.oposites.api.service.RamaOposicionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/oposiciones")
@RequiredArgsConstructor
public class AdminRamaController {

    private final RamaOposicionService ramaService;

    @PostMapping
    public ResponseEntity<RamaResponse> crear(@Valid @RequestBody CreateRamaOposicionRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ramaService.crear(request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<RamaResponse> actualizar(
            @PathVariable Long id,
            @RequestBody UpdateRamaOposicionRequest request) {
        return ResponseEntity.ok(ramaService.actualizar(id, request));
    }

    /** Soft delete: marca active=false */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> desactivar(@PathVariable Long id) {
        ramaService.desactivar(id);
        return ResponseEntity.noContent().build();
    }
}
