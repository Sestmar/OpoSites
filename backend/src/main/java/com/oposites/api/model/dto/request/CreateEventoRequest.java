package com.oposites.api.model.dto.request;

import com.oposites.api.model.enums.TipoEvento;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class CreateEventoRequest {

    @NotBlank(message = "El título es obligatorio")
    private String titulo;

    private String descripcion;

    @NotNull(message = "La fecha de inicio es obligatoria")
    private LocalDateTime fechaInicio;

    private LocalDateTime fechaFin;

    @NotNull(message = "El tipo es obligatorio")
    private TipoEvento tipo;

    // Nullable: evento manual puede no estar ligado a una rama
    private Long ramaId;
}
