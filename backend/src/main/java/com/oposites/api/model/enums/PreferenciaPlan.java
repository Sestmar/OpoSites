package com.oposites.api.model.enums;

import com.fasterxml.jackson.annotation.JsonProperty;

public enum PreferenciaPlan {
    @JsonProperty("teoria")  TEORIA,
    @JsonProperty("test")    TEST,
    @JsonProperty("mixto")   MIXTO
}
