package com.oposites.api.model.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CreateRamaOposicionRequest {

    @NotBlank(message = "El nombre es obligatorio")
    private String nombre;

    private String temarioOficialUrl;
}
