package com.oposites.api.model.dto.request;

import com.oposites.api.model.enums.PreferenciaPlan;
import lombok.Data;

import java.time.LocalDate;
import java.util.Map;

@Data
public class UpdatePlanConfiguracionRequest {

    private Integer horasSemana;
    private PreferenciaPlan preferencia;

    // Opcional: actualiza fecha_examen_objetivo en usuarios directamente
    private LocalDate fechaExamenObjetivo;

    // null = no modificar; mapa vacío = quitar todas las restricciones
    private Map<String, Integer> diasDisponibles;
}
