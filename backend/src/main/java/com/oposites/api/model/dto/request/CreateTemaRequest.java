package com.oposites.api.model.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

@Data
public class CreateTemaRequest {

    @NotBlank(message = "El nombre es obligatorio")
    private String nombre;

    @NotNull(message = "El orden es obligatorio")
    @Positive(message = "El orden debe ser un número positivo")
    private Integer orden;

    private String descripcionCorta;
}
