package com.oposites.api.controller;

import com.oposites.api.model.dto.request.CreateNoticiaRequest;
import com.oposites.api.model.dto.request.UpdateEstadoNoticiaRequest;
import com.oposites.api.model.dto.request.UpdateNoticiaRequest;
import com.oposites.api.model.dto.response.NoticiaResponse;
import com.oposites.api.service.NoticiaIngestionService;
import com.oposites.api.service.NoticiaService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Noticias", description = "Noticias y convocatorias por oposición; marcado de leídas")
@RestController
@RequestMapping("/api/v1/admin/noticias")
@RequiredArgsConstructor
public class AdminNoticiaController {

    private final NoticiaService noticiaService;
    private final NoticiaIngestionService noticiaIngestionService;

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

    @GetMapping("/borradores")
    public ResponseEntity<Page<NoticiaResponse>> listarBorradores(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(noticiaService.listarBorradores(PageRequest.of(page, size)));
    }

    @PatchMapping("/{id}/estado")
    public ResponseEntity<NoticiaResponse> actualizarEstado(
            @PathVariable Long id,
            @Valid @RequestBody UpdateEstadoNoticiaRequest request) {
        return ResponseEntity.ok(noticiaService.actualizarEstadoEditorial(id, request.getEstadoEditorial()));
    }

    @PostMapping("/ingesta/ejecutar")
    public ResponseEntity<NoticiaIngestionService.IngestionResult> ejecutarIngesta() {
        return ResponseEntity.ok(noticiaIngestionService.ejecutarIngesta());
    }
}
