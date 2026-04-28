package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;
import java.util.List;

@Data
@Builder
public class SimulacroResponse {

    private Long id;
    private Long ramaId;
    private String nombre;
    private int duracionMinutos;
    private int preguntasCount;
    private List<Long> temasIncluidos;
    private LocalDate fechaOficial;
}
