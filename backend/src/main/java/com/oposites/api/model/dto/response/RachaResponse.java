package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;

@Data
@Builder
public class RachaResponse {

    private int rachaActual;
    private int mejorRacha;
    private LocalDate ultimoEstudio;
}
