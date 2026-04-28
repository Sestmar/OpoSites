package com.oposites.api.controller;

import com.oposites.api.model.dto.request.UpdatePlanConfiguracionRequest;
import com.oposites.api.model.dto.response.PlanConfiguracionResponse;
import com.oposites.api.model.dto.response.PlanHoyResponse;
import com.oposites.api.model.dto.response.PlanTareaResponse;
import com.oposites.api.service.PlanService;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Plan", description = "Plan de estudio diario: tareas de hoy, configuración y completado")
@RestController
@RequestMapping("/api/v1/plan")
@RequiredArgsConstructor
public class PlanController {

    private final PlanService planService;

    @GetMapping("/hoy")
    public ResponseEntity<PlanHoyResponse> getPlanHoy(
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(planService.getPlanHoy(user.getUsername()));
    }

    @GetMapping("/configuracion")
    public ResponseEntity<PlanConfiguracionResponse> getConfiguracion(
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(planService.getConfiguracion(user.getUsername()));
    }

    @PutMapping("/configuracion")
    public ResponseEntity<PlanConfiguracionResponse> actualizarConfiguracion(
            @AuthenticationPrincipal UserDetails user,
            @RequestBody UpdatePlanConfiguracionRequest request) {
        return ResponseEntity.ok(planService.actualizarConfiguracion(user.getUsername(), request));
    }

    @PostMapping("/generar")
    public ResponseEntity<PlanHoyResponse> generarPlan(
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(planService.generarPlan(user.getUsername()));
    }

    @PutMapping("/tarea/{tareaId}/completar")
    public ResponseEntity<PlanTareaResponse> completarTarea(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long tareaId) {
        return ResponseEntity.ok(planService.completarTarea(tareaId, user.getUsername()));
    }
}
