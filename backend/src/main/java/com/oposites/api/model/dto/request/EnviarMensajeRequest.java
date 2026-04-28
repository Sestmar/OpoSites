package com.oposites.api.model.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class EnviarMensajeRequest {

    @NotBlank(message = "El mensaje no puede estar vacío")
    @Size(max = 2000, message = "El mensaje no puede superar los 2000 caracteres")
    private String mensaje;
}
