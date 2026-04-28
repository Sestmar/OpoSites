package com.oposites.api.model.dto.request;

import jakarta.validation.constraints.Positive;
import lombok.Data;

@Data
public class UpdateTemaRequest {

    private String nombre;

    @Positive(message = "El orden debe ser un número positivo")
    private Integer orden;

    private String descripcionCorta;
}
