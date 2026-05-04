package com.oposites.api.model.entity;

import com.oposites.api.model.enums.EstadoSession;
import com.oposites.api.model.enums.TipoSession;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "test_sessions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TestSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    // null para tests libres
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "simulacro_id")
    private Simulacro simulacro;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "rama_id", nullable = false)
    private RamaOposicion rama;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 50)
    private TipoSession tipo;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 50)
    @Builder.Default
    private EstadoSession estado = EstadoSession.EN_CURSO;

    // IDs de preguntas seleccionadas para esta sesión (orden de presentación)
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "pregunta_ids", columnDefinition = "jsonb", nullable = false)
    private List<Long> preguntaIds;

    // null hasta completar
    private Double nota;

    @Column(name = "total_preguntas", nullable = false)
    private int totalPreguntas;

    // null hasta completar
    private Integer correctas;

    @Column(name = "fecha_inicio", nullable = false)
    private LocalDateTime fechaInicio;

    // null hasta completar
    @Column(name = "fecha_fin")
    private LocalDateTime fechaFin;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        if (this.fechaInicio == null) {
            this.fechaInicio = LocalDateTime.now();
        }
    }
}
