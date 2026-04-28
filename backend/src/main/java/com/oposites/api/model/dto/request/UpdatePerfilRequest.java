package com.oposites.api.model.dto.request;

import lombok.Data;

import java.time.LocalDate;

@Data
public class UpdatePerfilRequest {

    // Todos los campos son opcionales (PATCH semántico sobre PUT)
    private String nombre;
    private String ciudad;
    private LocalDate fechaExamenObjetivo;
}
