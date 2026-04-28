package com.oposites.api.model.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class UpdateRamaRequest {

    @NotNull(message = "El ramaId es obligatorio")
    private Long ramaId;
}
