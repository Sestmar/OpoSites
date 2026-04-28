package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class RamaResponse {

    private Long id;
    private String nombre;
    private String temarioOficialUrl;
    private int temasCount;
    private boolean active;
}
