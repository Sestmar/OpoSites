package com.oposites.api.model.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "progreso_usuario")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProgresoUsuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    // nullable: las respuestas de sesiones de repaso IA no tienen pregunta real
    @ManyToOne(fetch = FetchType.LAZY, optional = true)
    @JoinColumn(name = "pregunta_id", nullable = true)
    private Pregunta pregunta;

    // 5.2 — Tema directo cuando no hay pregunta (repaso IA)
    @ManyToOne(fetch = FetchType.LAZY, optional = true)
    @JoinColumn(name = "tema_id", nullable = true)
    private Tema tema;

    // nullable: puede haber respuestas fuera de una sesión (futuro)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "test_session_id")
    private TestSession testSession;

    @Column(name = "respuesta_usuario", length = 500)
    private String respuestaUsuario;

    @Column(nullable = false)
    private boolean correcto;

    @Column(name = "fecha_respuesta", nullable = false)
    private LocalDateTime fechaRespuesta;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        if (this.fechaRespuesta == null) {
            this.fechaRespuesta = LocalDateTime.now();
        }
    }
}
