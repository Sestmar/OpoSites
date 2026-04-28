package com.oposites.api.controller;

import com.oposites.api.model.dto.request.CreateEventoRequest;
import com.oposites.api.model.dto.request.UpdateEventoRequest;
import com.oposites.api.model.dto.response.EventoResponse;
import com.oposites.api.model.enums.TipoEvento;
import com.oposites.api.service.CalendarioService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@Tag(name = "Calendario", description = "Eventos personales del opositor: manuales y auto-generados tras tests/simulacros")
@RestController
@RequestMapping("/api/v1/calendario/eventos")
@RequiredArgsConstructor
public class CalendarioController {

    private final CalendarioService calendarioService;

    @GetMapping
    public ResponseEntity<List<EventoResponse>> listar(
            @AuthenticationPrincipal UserDetails user,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime desde,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime hasta,
            @RequestParam(required = false) TipoEvento tipo) {
        return ResponseEntity.ok(calendarioService.listarEventos(user.getUsername(), desde, hasta, tipo));
    }

    @GetMapping("/{id}")
    public ResponseEntity<EventoResponse> detalle(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long id) {
        return ResponseEntity.ok(calendarioService.getEvento(id, user.getUsername()));
    }

    @PostMapping
    public ResponseEntity<EventoResponse> crear(
            @AuthenticationPrincipal UserDetails user,
            @Valid @RequestBody CreateEventoRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(calendarioService.crearManual(user.getUsername(), request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<EventoResponse> editar(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long id,
            @RequestBody UpdateEventoRequest request) {
        return ResponseEntity.ok(calendarioService.editarManual(id, user.getUsername(), request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long id) {
        calendarioService.eliminarManual(id, user.getUsername());
        return ResponseEntity.noContent().build();
    }
}
