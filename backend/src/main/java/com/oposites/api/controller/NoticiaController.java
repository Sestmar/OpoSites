package com.oposites.api.controller;

import com.oposites.api.exception.AppException;
import com.oposites.api.model.dto.response.NoticiaConteosResponse;
import com.oposites.api.model.dto.response.NoticiaResumenResponse;
import com.oposites.api.model.dto.response.NoticiaResponse;
import com.oposites.api.model.enums.TipoNoticia;
import com.oposites.api.service.NoticiaService;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Noticias", description = "Noticias y convocatorias por oposición; marcado de leídas")
@RestController
@RequestMapping("/api/v1/noticias")
@RequiredArgsConstructor
public class NoticiaController {

    private final NoticiaService noticiaService;

    @GetMapping
    public ResponseEntity<Page<NoticiaResumenResponse>> listar(
            @AuthenticationPrincipal UserDetails user,
            @RequestParam(required = false) String tipo,
            @RequestParam(required = false) Long ramaId,
            @RequestParam(required = false) String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        final TipoNoticia tipoNoticia;
        try {
            tipoNoticia = TipoNoticia.fromQueryParam(tipo);
        } catch (IllegalArgumentException ex) {
            throw new AppException("Parámetro inválido: tipo", HttpStatus.BAD_REQUEST);
        }

        return ResponseEntity.ok(noticiaService.listarNoticias(
                user.getUsername(), ramaId, tipoNoticia, q, PageRequest.of(page, size)));
    }

    @GetMapping("/conteos")
    public ResponseEntity<NoticiaConteosResponse> conteos(
            @AuthenticationPrincipal UserDetails user,
            @RequestParam(required = false) Long ramaId) {
        return ResponseEntity.ok(noticiaService.getConteos(ramaId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<NoticiaResponse> detalle(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long id) {
        return ResponseEntity.ok(noticiaService.getDetalle(id, user.getUsername()));
    }

    @PostMapping("/{id}/leer")
    public ResponseEntity<Void> marcarLeida(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long id) {
        noticiaService.marcarLeida(id, user.getUsername());
        return ResponseEntity.noContent().build();
    }
}
