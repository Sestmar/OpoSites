package com.oposites.api.model.dto.request;

import com.oposites.api.model.enums.TipoMaterial;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class GenerarMaterialRequest {

    @NotNull(message = "El tipo de material es obligatorio")
    private TipoMaterial tipo;
}
