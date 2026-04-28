package com.oposites.api.model.dto.response;

import com.oposites.api.model.enums.TipoNoticia;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class NoticiaResponse {

    private Long id;
    private String titulo;
    private String contenido;
    private String urlExterna;
    private TipoNoticia tipo;
    private Long ramaId;
    private String nombreRama;
    private String fechaPublicacion; // formato dd/MM/yyyy HH:mm
    private boolean leida;
}
