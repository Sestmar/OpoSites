package com.oposites.api.model.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "ramas_oposiciones")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RamaOposicion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nombre;

    @Column(name = "temario_oficial_url", length = 500)
    private String temarioOficialUrl;

    // Contador mantenido manualmente desde TemaService (crear/eliminar tema)
    @Column(name = "temas_count", nullable = false)
    @Builder.Default
    private int temasCount = 0;

    @Column(nullable = false)
    @Builder.Default
    private boolean active = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
