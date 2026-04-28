package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;
import java.util.List;

@Data
@Builder
public class PlanHoyResponse {

    private LocalDate fecha;
    private List<PlanTareaResponse> tareas;
    private int tareasCompletadas;
    private int totalTareas;
}
