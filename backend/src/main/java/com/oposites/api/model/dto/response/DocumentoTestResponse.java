package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Value;

import java.time.LocalDateTime;
import java.util.List;

@Value
@Builder
public class DocumentoTestResponse {
    Long id;
    Long documentoId;
    List<DocumentoTestPreguntaResponse> preguntas;
    LocalDateTime creadoEn;
}
