package com.oposites.api.model.dto.request;

import com.oposites.api.validation.StrongPassword;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class RegisterRequest {

    @NotBlank(message = "El email es obligatorio")
    @Email(message = "Formato de email inválido")
    private String email;

    @NotBlank(message = "La contraseña es obligatoria")
    @StrongPassword
    private String password;

    @NotBlank(message = "El nombre es obligatorio")
    private String nombre;

    private String ciudad;
}
