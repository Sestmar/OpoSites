package com.oposites.api.model.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "simulacros")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Simulacro {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "rama_id", nullable = false)
    private RamaOposicion rama;

    @Column(nullable = false)
    private String nombre;

    @Column(name = "duracion_minutos", nullable = false)
    private int duracionMinutos;

    @Column(name = "preguntas_count", nullable = false)
    private int preguntasCount;

    // IDs de temas de los que se seleccionan preguntas al iniciar el simulacro
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "temas_incluidos", columnDefinition = "jsonb", nullable = false)
    private List<Long> temasIncluidos;

    @Column(name = "fecha_oficial")
    private LocalDate fechaOficial;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
