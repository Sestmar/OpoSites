package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class TestIniciadoResponse {

    private Long sessionId;
    private List<PreguntaResponse> preguntas;
    // null para tests libres sin tiempo asignado
    private Integer tiempoMinutos;
}
