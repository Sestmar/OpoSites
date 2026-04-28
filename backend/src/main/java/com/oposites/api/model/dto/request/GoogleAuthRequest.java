package com.oposites.api.model.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class GoogleAuthRequest {

    // ID Token obtenido por Flutter mediante google_sign_in
    @NotBlank(message = "El idToken de Google es obligatorio")
    private String idToken;
}
