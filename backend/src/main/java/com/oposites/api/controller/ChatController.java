package com.oposites.api.controller;

import com.oposites.api.model.dto.request.EnviarMensajeRequest;
import com.oposites.api.model.dto.response.ConversacionResponse;
import com.oposites.api.model.dto.response.EnviarMensajeResponse;
import com.oposites.api.model.dto.response.MensajeResponse;
import com.oposites.api.service.ChatIAService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ChatIAService chatIAService;

    @GetMapping("/conversaciones")
    public ResponseEntity<List<ConversacionResponse>> listarConversaciones(
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(chatIAService.listarConversaciones(user.getUsername()));
    }

    @PostMapping("/conversaciones")
    public ResponseEntity<ConversacionResponse> crearConversacion(
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(chatIAService.crearConversacion(user.getUsername()));
    }

    @GetMapping("/conversaciones/{id}/mensajes")
    public ResponseEntity<List<MensajeResponse>> listarMensajes(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long id) {
        return ResponseEntity.ok(chatIAService.listarMensajes(id, user.getUsername()));
    }

    @PostMapping("/conversaciones/{id}/mensajes")
    public ResponseEntity<EnviarMensajeResponse> enviarMensaje(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long id,
            @Valid @RequestBody EnviarMensajeRequest request) {
        return ResponseEntity.ok(chatIAService.enviarMensaje(id, user.getUsername(), request));
    }

    @DeleteMapping("/conversaciones/{id}")
    public ResponseEntity<Void> eliminarConversacion(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long id) {
        chatIAService.eliminarConversacion(id, user.getUsername());
        return ResponseEntity.noContent().build();
    }
}
