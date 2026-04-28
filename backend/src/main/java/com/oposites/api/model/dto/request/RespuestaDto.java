package com.oposites.api.model.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class RespuestaDto {

    @NotNull(message = "El preguntaId es obligatorio")
    private Long preguntaId;

    // null si el usuario no respondió (pregunta omitida)
    private String respuestaUsuario;
}
