package com.oposites.api.model.dto.response;

import com.oposites.api.model.enums.TipoPregunta;
import lombok.Builder;
import lombok.Data;

import java.util.List;

/**
 * Respuesta pública de una pregunta.
 * NO incluye respuestaCorrecta ni explicacion.
 * Esos campos solo se devuelven via PreguntaRespuestaResponse (Fase 3+).
 */
@Data
@Builder
public class PreguntaResponse {

    private Long id;
    private Long temaId;
    private String enunciado;
    private TipoPregunta tipo;
    private List<String> opciones;
    private int dificultad;
}
