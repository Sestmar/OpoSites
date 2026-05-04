package com.oposites.api.model.dto.request;

import com.oposites.api.model.enums.TipoPlanTarea;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CreatePlanTareaRequest {

    @NotNull(message = "El tipo de tarea es obligatorio")
    private TipoPlanTarea tipo;

    /** Descripción libre opcional. Si se omite, el servicio genera una genérica. */
    @Size(max = 200, message = "La descripción no puede superar los 200 caracteres")
    private String descripcion;
}
