package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ResultadoPreguntaDto {

    private Long preguntaId;
    private boolean correcto;
    private String respuestaUsuario;
    private String respuestaCorrecta;
    private String explicacion;
}
