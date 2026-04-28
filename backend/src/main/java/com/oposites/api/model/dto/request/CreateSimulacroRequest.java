package com.oposites.api.model.dto.request;

import jakarta.validation.constraints.*;
import lombok.Data;

import java.time.LocalDate;
import java.util.List;

@Data
public class CreateSimulacroRequest {

    @NotBlank(message = "El nombre es obligatorio")
    private String nombre;

    @NotNull
    @Positive(message = "La duración debe ser positiva")
    private Integer duracionMinutos;

    @NotNull
    @Positive(message = "El número de preguntas debe ser positivo")
    private Integer preguntasCount;

    @NotNull
    @NotEmpty(message = "Debe indicar al menos un tema")
    private List<Long> temasIncluidos;

    private LocalDate fechaOficial;
}
