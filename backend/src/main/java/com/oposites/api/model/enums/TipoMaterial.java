package com.oposites.api.model.enums;

import com.fasterxml.jackson.annotation.JsonProperty;

public enum TipoMaterial {
    @JsonProperty("flashcards")      FLASHCARDS,
    @JsonProperty("resumen")         RESUMEN,
    @JsonProperty("conceptos_clave") CONCEPTOS_CLAVE
}
