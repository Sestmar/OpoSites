package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AnalisisTemaDto {

    private Long temaId;
    private String nombreTema;
    private int correctas;
    private int total;
    private double porcentajeAcierto;
}
