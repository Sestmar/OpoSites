package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class TemaResponse {

    private Long id;
    private Long ramaId;
    private String nombre;
    private int orden;
    private String descripcionCorta;
    private int preguntasCount;
}
