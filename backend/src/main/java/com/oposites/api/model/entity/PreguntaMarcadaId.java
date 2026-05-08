package com.oposites.api.model.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.*;

import java.io.Serializable;

@Embeddable
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode
public class PreguntaMarcadaId implements Serializable {

    @Column(name = "usuario_id")
    private Long usuarioId;

    @Column(name = "pregunta_id")
    private Long preguntaId;
}
