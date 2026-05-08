package com.oposites.api.model.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "preguntas_marcadas")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PreguntaMarcada {

    @EmbeddedId
    private PreguntaMarcadaId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("usuarioId")
    @JoinColumn(name = "usuario_id")
    private Usuario usuario;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("preguntaId")
    @JoinColumn(name = "pregunta_id")
    private Pregunta pregunta;

    @Column(name = "marcada_en", nullable = false, updatable = false)
    private LocalDateTime marcadaEn;

    @PrePersist
    protected void onCreate() {
        if (this.marcadaEn == null) {
            this.marcadaEn = LocalDateTime.now();
        }
    }
}
