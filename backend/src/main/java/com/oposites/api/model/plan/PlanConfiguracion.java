package com.oposites.api.model.plan;

import com.oposites.api.model.enums.PreferenciaPlan;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

/**
 * POJO serializado como JSON en el campo plan_manual (JSONB) de la tabla usuarios.
 * No es una entidad JPA — se convierte manualmente con Jackson en PlanService.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PlanConfiguracion {

    @Builder.Default
    private int horasSemana = 5;

    @Builder.Default
    private PreferenciaPlan preferencia = PreferenciaPlan.MIXTO;

    /**
     * Días de la semana disponibles para estudiar.
     *
     * Clave: nombre del día en inglés mayúsculas ("MONDAY"…"SUNDAY").
     * Valor: horas disponibles ese día (1–8).
     *
     * Semántica:
     *   null              → sin restricción (comportamiento por defecto, compatibilidad con usuarios existentes)
     *   clave ausente     → día no disponible, no se generan tareas
     *   valor 0           → día no disponible, no se generan tareas
     *   valor 1..8        → día disponible, se generan tareas normalmente
     */
    private Map<String, Integer> diasDisponibles;
}
