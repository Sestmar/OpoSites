package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class ProgresoResumenResponse {

    private long totalRespondidas;
    private long totalCorrectas;
    private double porcentajeAciertosGlobal;
    private int rachaActual;
    private List<TemaDebilDto> temasDebiles;
}
