package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class ResultadoTestResponse {

    private Long sessionId;
    private double nota;        // 0.0 – 10.0
    private int correctas;
    private int total;
    private List<ResultadoPreguntaDto> detalle;
    // null para tests libres; poblado para simulacros
    private List<AnalisisTemaDto> analisisPorTema;
}
