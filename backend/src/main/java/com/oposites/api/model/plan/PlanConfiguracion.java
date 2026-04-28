package com.oposites.api.model.plan;

import com.oposites.api.model.enums.PreferenciaPlan;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

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
}
