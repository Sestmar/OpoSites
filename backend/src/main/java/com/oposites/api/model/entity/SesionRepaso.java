package com.oposites.api.model.entity;

import com.oposites.api.model.enums.EstadoSesionRepaso;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "sesiones_repaso")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SesionRepaso {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "rama_id")
    private RamaOposicion rama;

    /** [{id, nombre, porcentajeAcierto}] */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb", nullable = false)
    private List<TemaRepasoInfo> temas;

    /** [{enunciado, opciones[], respuestaCorrecta (0-3), explicacion, temaId, temaNombre}] */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb", nullable = false)
    private List<PreguntaRepaso> preguntas;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private EstadoSesionRepaso estado = EstadoSesionRepaso.EN_CURSO;

    @Column(name = "total_preguntas", nullable = false)
    private int totalPreguntas;

    private Integer correctas;

    private Double puntuacion;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "completado_at")
    private LocalDateTime completadoAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    // Lombok no genera estos métodos con @Builder.Default + JDK 21 — explícitos:
    public Integer getCorretas() { return correctas; }
    public void setCorretas(Integer correctas) { this.correctas = correctas; }

    // ─── POJOs serializados en JSONB ──────────────────────────────────────────

    @lombok.Data
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    @lombok.Builder
    public static class TemaRepasoInfo {
        private Long id;
        private String nombre;
        private double porcentajeAcierto;
    }

    @lombok.Data
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    @lombok.Builder
    public static class PreguntaRepaso {
        private String enunciado;
        private List<String> opciones;
        private int respuestaCorrecta;   // índice 0-3
        private String explicacion;
        private Long temaId;
        private String temaNombre;
    }
}
