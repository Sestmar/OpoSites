package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class ResultadoSesionRepasoResponse {

    private Long sesionId;
    private double puntuacion;
    private int totalPreguntas;
    private int correctas;
    private List<DetalleRespuestaDto> respuestas;

    @Data
    @Builder
    public static class DetalleRespuestaDto {
        private int preguntaIndex;
        private String enunciado;
        private boolean esCorrecta;
        private String temaNombre;
        private int respuestaUsuario;
        private int respuestaCorrecta;
        private String explicacion;
    }
}
