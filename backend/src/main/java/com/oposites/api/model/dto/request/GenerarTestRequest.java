package com.oposites.api.model.dto.request;

import jakarta.validation.constraints.*;
import lombok.Data;

import java.util.List;

@Data
public class GenerarTestRequest {

    @NotNull(message = "El ramaId es obligatorio")
    private Long ramaId;

    // null o vacío = todas las preguntas de la rama sin filtrar por tema
    private List<Long> temaIds;

    @Min(value = 1, message = "La cantidad mínima es 1")
    @Max(value = 100, message = "La cantidad máxima es 100")
    private int cantidad = 10;

    // null = sin filtro de dificultad
    @Min(value = 1, message = "Dificultad mínima: 1")
    @Max(value = 5, message = "Dificultad máxima: 5")
    private Integer dificultad;

    // null = sin límite de tiempo en el cliente
    @Positive
    private Integer tiempoMinutos;
}
