package com.oposites.api.model.enums;

import com.fasterxml.jackson.annotation.JsonProperty;

public enum TipoEvento {
    @JsonProperty("estudio")      ESTUDIO,
    @JsonProperty("simulacro")    SIMULACRO,
    @JsonProperty("convocatoria") CONVOCATORIA,
    @JsonProperty("manual")       MANUAL
}
