package com.oposites.api.model.enums;

import com.fasterxml.jackson.annotation.JsonProperty;

public enum TipoNoticia {
    @JsonProperty("convocatoria") CONVOCATORIA,
    @JsonProperty("cambio")       CAMBIO,
    @JsonProperty("noticia")      NOTICIA;

    public static TipoNoticia fromQueryParam(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        for (TipoNoticia tipo : values()) {
            if (tipo.name().equalsIgnoreCase(value)) {
                return tipo;
            }
        }
        throw new IllegalArgumentException("TipoNoticia inválido");
    }
}
