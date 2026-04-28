package com.oposites.api.model.dto.response;

import com.oposites.api.model.enums.Role;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
public class UsuarioResponse {

    private Long id;
    private String email;
    private String nombre;
    private String ciudad;
    private Long ramaPrincipalId;
    private LocalDate fechaExamenObjetivo;
    private boolean enabledChatPrivate;
    private Role role;
    private LocalDateTime fechaRegistro;
}
