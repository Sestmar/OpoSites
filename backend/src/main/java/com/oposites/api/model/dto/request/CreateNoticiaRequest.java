package com.oposites.api.model.dto.request;

import com.oposites.api.model.enums.TipoNoticia;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class CreateNoticiaRequest {

    @NotBlank(message = "El título es obligatorio")
    private String titulo;

    @NotBlank(message = "El contenido es obligatorio")
    private String contenido;

    private String urlExterna;

    @NotNull(message = "El tipo es obligatorio")
    private TipoNoticia tipo;

    // Nullable: null = noticia global visible para todos
    private Long ramaId;

    @NotNull(message = "La fecha de publicación es obligatoria")
    private LocalDateTime fechaPublicacion;
}
