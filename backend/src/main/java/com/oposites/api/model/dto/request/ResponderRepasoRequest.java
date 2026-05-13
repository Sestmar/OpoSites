package com.oposites.api.model.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ResponderRepasoRequest {

    @NotNull
    @Min(0)
    private Integer preguntaIndex;

    @NotNull
    @Min(0) @Max(3)
    private Integer respuestaUsuario;
}
