package com.oposites.api.model.dto.request;

import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.time.LocalDate;
import java.util.List;

@Data
public class UpdateSimulacroRequest {

    private String nombre;

    @Positive
    private Integer duracionMinutos;

    @Positive
    private Integer preguntasCount;

    private List<Long> temasIncluidos;
    private LocalDate fechaOficial;
}
