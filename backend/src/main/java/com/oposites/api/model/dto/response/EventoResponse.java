package com.oposites.api.model.dto.response;

import com.oposites.api.model.enums.TipoEvento;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class EventoResponse {

    private Long id;
    private String titulo;
    private String descripcion;
    private LocalDateTime fechaInicio;
    private LocalDateTime fechaFin;
    private TipoEvento tipo;
    private Long ramaId;
    private String nombreRama;
    private boolean autoGenerado;
}
