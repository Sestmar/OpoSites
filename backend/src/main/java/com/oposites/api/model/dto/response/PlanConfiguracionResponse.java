package com.oposites.api.model.dto.response;

import com.oposites.api.model.enums.PreferenciaPlan;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;
import java.util.Map;

@Data
@Builder
public class PlanConfiguracionResponse {

    private int horasSemana;
    private PreferenciaPlan preferencia;
    private LocalDate fechaExamenObjetivo;
    private Long diasHastaExamen; // null si no hay fecha configurada
    private Map<String, Integer> diasDisponibles; // null = sin restricción
}
