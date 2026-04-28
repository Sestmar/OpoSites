package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class EnviarMensajeResponse {

    private Long id;
    private String mensaje;
    private LocalDateTime createdAt;
}
