package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class IniciarSesionRepasoResponse {

    private Long sesionId;
    private int totalPreguntas;

    /** Índice de la primera pregunta sin responder. 0 para sesiones nuevas, >0 para sesiones recuperadas. */
    private int preguntaActual;

    /** Temas sobre los que se repasa en esta sesión. */
    private List<TemaRepasoDto> temas;

    /** Preguntas sin revelar la respuesta correcta ni la explicación. */
    private List<PreguntaRepasoDto> preguntas;

    @Data
    @Builder
    public static class TemaRepasoDto {
        private Long id;
        private String nombre;
        private double porcentajeAcierto;
    }

    @Data
    @Builder
    public static class PreguntaRepasoDto {
        private int index;
        private String enunciado;
        private List<String> opciones;
        private String temaNombre;
    }
}
