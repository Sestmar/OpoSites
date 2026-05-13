package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ResponderRepasoResponse {

    private boolean esCorrecta;
    private int respuestaCorrecta;   // índice 0-3 de la opción correcta
    private String explicacion;
    private boolean sesionCompletada;
    private Double puntuacion;       // null hasta completar
}
