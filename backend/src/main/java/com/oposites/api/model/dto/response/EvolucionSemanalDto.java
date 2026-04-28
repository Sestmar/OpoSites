package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class EvolucionSemanalDto {

    private String semana;        // Formato ISO: "2026-W17"
    private double notaMedia;
    private long testsCompletados;
}
