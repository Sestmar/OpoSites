package com.oposites.api.model.dto.request;

import com.oposites.api.model.enums.TipoNoticia;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class UpdateNoticiaRequest {

    private String titulo;
    private String contenido;
    private String urlExterna;
    private TipoNoticia tipo;
    private LocalDateTime fechaPublicacion;
    private Boolean active;
}
