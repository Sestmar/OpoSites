package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ProgresoTemaResponse {

    private Long temaId;
    private String nombre;
    private long totalRespondidas;
    private long correctas;
    private double porcentajeAcierto;
}
