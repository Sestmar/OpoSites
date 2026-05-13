package com.oposites.api.model.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "respuestas_sesion_repaso")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RespuestaSesionRepaso {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "sesion_repaso_id", nullable = false)
    private SesionRepaso sesionRepaso;

    @Column(name = "pregunta_index", nullable = false)
    private int preguntaIndex;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tema_id")
    private Tema tema;

    @Column(name = "respuesta_usuario", nullable = false)
    private int respuestaUsuario;   // índice 0-3

    @Column(name = "es_correcta", nullable = false)
    private boolean esCorrecta;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
