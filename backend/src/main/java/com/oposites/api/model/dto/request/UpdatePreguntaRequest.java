package com.oposites.api.model.dto.request;

import com.oposites.api.model.enums.TipoPregunta;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;

import java.util.List;

@Data
public class UpdatePreguntaRequest {

    private String enunciado;
    private TipoPregunta tipo;
    private List<String> opciones;
    private String respuestaCorrecta;
    private String explicacion;

    @Min(value = 1, message = "La dificultad mínima es 1")
    @Max(value = 5, message = "La dificultad máxima es 5")
    private Integer dificultad;
}
