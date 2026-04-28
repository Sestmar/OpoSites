package com.oposites.api.model.dto.request;

import lombok.Data;

@Data
public class UpdateRamaOposicionRequest {

    // Todos opcionales: solo se actualizan los campos que vengan no-null
    private String nombre;
    private String temarioOficialUrl;
    private Boolean active;
}
