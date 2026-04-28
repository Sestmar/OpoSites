package com.oposites.api.model.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "temas")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Tema {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "rama_id", nullable = false)
    private RamaOposicion rama;

    @Column(nullable = false)
    private String nombre;

    @Column(nullable = false)
    @Builder.Default
    private int orden = 0;

    @Column(name = "descripcion_corta", length = 500)
    private String descripcionCorta;

    // Contador mantenido manualmente desde PreguntaService (crear/eliminar pregunta)
    @Column(name = "preguntas_count", nullable = false)
    @Builder.Default
    private int preguntasCount = 0;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
