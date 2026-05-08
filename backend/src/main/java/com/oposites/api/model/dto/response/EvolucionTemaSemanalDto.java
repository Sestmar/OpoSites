package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class EvolucionTemaSemanalDto {

    /** Semana ISO: "2026-W17". Ordenados cronológicamente ascendente. */
    private String semana;

    /** Porcentaje de acierto esa semana para el tema, de 0.0 a 100.0. */
    private double porcentajeAcierto;

    /** Preguntas respondidas esa semana en el tema. */
    private long totalRespondidas;
}
