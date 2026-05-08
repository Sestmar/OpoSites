package com.oposites.api.controller;

import com.oposites.api.model.dto.response.EvolucionSemanalDto;
import com.oposites.api.model.dto.response.EvolucionTemaSemanalDto;
import com.oposites.api.model.dto.response.ProgresoResumenResponse;
import com.oposites.api.model.dto.response.ProgresoTemaResponse;
import com.oposites.api.model.dto.response.RachaResponse;
import com.oposites.api.service.ProgresoService;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "Progreso", description = "Estadísticas del usuario: resumen, temas débiles, evolución semanal y racha")
@RestController
@RequestMapping("/api/v1/progreso")
@RequiredArgsConstructor
public class ProgresoController {

    private final ProgresoService progresoService;

    @GetMapping("/resumen")
    public ResponseEntity<ProgresoResumenResponse> resumen(
            @AuthenticationPrincipal UserDetails user,
            @RequestParam(required = false) Long ramaId) {
        return ResponseEntity.ok(progresoService.resumen(user.getUsername(), ramaId));
    }

    @GetMapping("/temas")
    public ResponseEntity<List<ProgresoTemaResponse>> estadisticasPorTema(
            @AuthenticationPrincipal UserDetails user,
            @RequestParam(required = false) Long ramaId) {
        return ResponseEntity.ok(progresoService.estadisticasPorTema(user.getUsername(), ramaId));
    }

    @GetMapping("/evolucion")
    public ResponseEntity<List<EvolucionSemanalDto>> evolucion(
            @AuthenticationPrincipal UserDetails user,
            @RequestParam(defaultValue = "12") int semanas) {
        return ResponseEntity.ok(progresoService.evolucion(user.getUsername(), semanas));
    }

    @GetMapping("/racha")
    public ResponseEntity<RachaResponse> racha(
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(progresoService.racha(user.getUsername()));
    }

    @GetMapping("/evolucion-tema")
    public ResponseEntity<List<EvolucionTemaSemanalDto>> evolucionTema(
            @AuthenticationPrincipal UserDetails user,
            @RequestParam Long temaId,
            @RequestParam(defaultValue = "4") int semanas) {
        return ResponseEntity.ok(
                progresoService.evolucionPorTema(user.getUsername(), temaId, semanas));
    }
}
