package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

/**
 * Devuelve la solución de una pregunta.
 * En Fase 3 se validará que el usuario ya haya respondido antes de devolver esto.
 * Por ahora accesible para cualquier USER autenticado.
 */
@Data
@Builder
public class PreguntaRespuestaResponse {

    private Long preguntaId;
    private String respuestaCorrecta;
    private String explicacion;
}
