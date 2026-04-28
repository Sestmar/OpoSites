package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class MensajeResponse {

    private Long id;
    private boolean esIa;
    private String mensaje;
    private LocalDateTime createdAt;
}
