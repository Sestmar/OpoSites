package com.oposites.api.model.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class NoticiaConteosResponse {
    private long todas;
    private long convocatorias;
    private long cambios;
    private long noticias;
}
