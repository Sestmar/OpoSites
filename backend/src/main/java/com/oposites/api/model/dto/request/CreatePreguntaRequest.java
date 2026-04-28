package com.oposites.api.model.dto.request;

import com.oposites.api.model.enums.TipoPregunta;
import jakarta.validation.constraints.*;
import lombok.Data;

import java.util.List;

@Data
public class CreatePreguntaRequest {

    @NotBlank(message = "El enunciado es obligatorio")
    private String enunciado;

    @NotNull(message = "El tipo es obligatorio")
    private TipoPregunta tipo;

    // Obligatorio para MCQ y TRUE_FALSE; puede ser null para DESARROLLO
    private List<String> opciones;

    @NotBlank(message = "La respuesta correcta es obligatoria")
    private String respuestaCorrecta;

    private String explicacion;

    @NotNull(message = "La dificultad es obligatoria")
    @Min(value = 1, message = "La dificultad mínima es 1")
    @Max(value = 5, message = "La dificultad máxima es 5")
    private Integer dificultad;
}
