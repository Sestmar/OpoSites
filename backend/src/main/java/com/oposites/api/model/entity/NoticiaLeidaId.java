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
public class NoticiaLeidaId implements Serializable {

    @Column(name = "noticia_id")
    private Long noticiaId;

    @Column(name = "usuario_id")
    private Long usuarioId;
}
