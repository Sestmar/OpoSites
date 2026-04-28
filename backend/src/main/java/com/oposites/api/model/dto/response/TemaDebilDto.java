package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class TemaDebilDto {

    private Long temaId;
    private String nombre;
    private double porcentajeAcierto;
    private long totalRespondidas;
}
