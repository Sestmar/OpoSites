package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Value;

import java.util.List;

@Value
@Builder
public class DocumentoTestPreguntaResponse {
    Long id;
    String enunciado;
    List<String> opciones;
    int respuestaCorrecta;
    String explicacion;
    int orden;
}
