package com.oposites.api.model.dto.request;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class UpdateEventoRequest {

    private String titulo;
    private String descripcion;
    private LocalDateTime fechaInicio;
    private LocalDateTime fechaFin;
}
