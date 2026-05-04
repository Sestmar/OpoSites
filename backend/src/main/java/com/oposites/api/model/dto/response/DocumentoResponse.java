package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class DocumentoResponse {
    private Long id;
    private String nombre;
    private String tipoArchivo;
    private long tamanoBytes;
    private boolean textoDisponible;   // true si la extracción de texto fue exitosa
    private LocalDateTime creadoEn;
}
