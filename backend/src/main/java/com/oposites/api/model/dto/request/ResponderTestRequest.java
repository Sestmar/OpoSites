package com.oposites.api.model.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

/**
 * Reutilizado tanto para tests libres (POST /tests/responder)
 * como para simulacros (POST /simulacros/{id}/entregar).
 */
@Data
public class ResponderTestRequest {

    @NotNull(message = "El sessionId es obligatorio")
    private Long sessionId;

    @NotEmpty(message = "Debe enviar al menos una respuesta")
    @Valid
    private List<RespuestaDto> respuestas;
}
