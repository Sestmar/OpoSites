package com.oposites.api.model.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class RefreshTokenRequest {

    @NotBlank(message = "El refreshToken es obligatorio")
    private String refreshToken;
}
