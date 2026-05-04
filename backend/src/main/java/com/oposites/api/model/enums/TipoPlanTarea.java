package com.oposites.api.model.enums;

import com.fasterxml.jackson.annotation.JsonProperty;

public enum TipoPlanTarea {
    @JsonProperty("test")      TEST,
    @JsonProperty("repaso")    REPASO,
    @JsonProperty("simulacro") SIMULACRO
}
