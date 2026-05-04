package com.oposites.api.model.enums;

import com.fasterxml.jackson.annotation.JsonProperty;

public enum TipoNoticia {
    @JsonProperty("convocatoria") CONVOCATORIA,
    @JsonProperty("cambio")       CAMBIO,
    @JsonProperty("noticia")      NOTICIA
}
