package com.oposites.api.model.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "noticia_leida")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NoticiaLeida {

    @EmbeddedId
    private NoticiaLeidaId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("noticiaId")
    @JoinColumn(name = "noticia_id")
    private NoticiaConvocatoria noticia;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("usuarioId")
    @JoinColumn(name = "usuario_id")
    private Usuario usuario;

    @Column(name = "leida_at", nullable = false)
    private LocalDateTime leidaAt;

    @PrePersist
    protected void onCreate() {
        if (this.leidaAt == null) {
            this.leidaAt = LocalDateTime.now();
        }
    }
}
