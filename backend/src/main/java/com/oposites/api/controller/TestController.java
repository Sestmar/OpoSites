package com.oposites.api.controller;

import com.oposites.api.model.dto.request.GenerarTestRequest;
import com.oposites.api.model.dto.request.ResponderTestRequest;
import com.oposites.api.model.dto.response.PreguntaResponse;
import com.oposites.api.model.dto.response.ResultadoTestResponse;
import com.oposites.api.model.dto.response.TestIniciadoResponse;
import com.oposites.api.service.TestService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "Tests", description = "Generación y resolución de tests de práctica; historial de fallos")
@RestController
@RequestMapping("/api/v1/tests")
@RequiredArgsConstructor
public class TestController {

    private final TestService testService;

    @PostMapping("/generar")
    public ResponseEntity<TestIniciadoResponse> generar(
            @AuthenticationPrincipal UserDetails user,
            @Valid @RequestBody GenerarTestRequest request) {
        return ResponseEntity.ok(testService.generar(user.getUsername(), request));
    }

    @PostMapping("/responder")
    public ResponseEntity<ResultadoTestResponse> responder(
            @AuthenticationPrincipal UserDetails user,
            @Valid @RequestBody ResponderTestRequest request) {
        return ResponseEntity.ok(testService.responder(user.getUsername(), request));
    }

    @GetMapping("/fallos")
    public ResponseEntity<List<PreguntaResponse>> getFallos(
            @AuthenticationPrincipal UserDetails user,
            @RequestParam(required = false) Long ramaId,
            @RequestParam(required = false) Long temaId) {
        return ResponseEntity.ok(testService.getFallos(user.getUsername(), ramaId, temaId));
    }
}
