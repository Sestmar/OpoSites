package com.oposites.api.model.dto.response;

import com.fasterxml.jackson.databind.JsonNode;
import com.oposites.api.model.enums.TipoMaterial;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class MaterialGeneradoResponse {
    private Long id;
    private Long documentoId;
    private TipoMaterial tipo;
    private JsonNode contenido;   // JSON parseado para que el cliente lo reciba como objeto
    private LocalDateTime creadoEn;
}
