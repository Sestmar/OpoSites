package com.oposites.api.model.dto.request;

import com.oposites.api.model.enums.EstadoEditorialNoticia;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class UpdateEstadoNoticiaRequest {

    @NotNull(message = "El estado editorial es obligatorio")
    private EstadoEditorialNoticia estadoEditorial;
}
