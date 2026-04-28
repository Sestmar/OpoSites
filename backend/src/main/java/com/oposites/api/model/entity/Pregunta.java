package com.oposites.api.model.entity;

import com.oposites.api.model.converter.JsonStringListConverter;
import com.oposites.api.model.enums.TipoPregunta;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "preguntas")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Pregunta {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "tema_id", nullable = false)
    private Tema tema;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String enunciado;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 50)
    private TipoPregunta tipo;

    // Lista de opciones almacenada como JSONB en PostgreSQL
    @Convert(converter = JsonStringListConverter.class)
    @Column(columnDefinition = "jsonb")
    private List<String> opciones;

    @Column(name = "respuesta_correcta", nullable = false, length = 500)
    private String respuestaCorrecta;

    @Column(columnDefinition = "TEXT")
    private String explicacion;

    // 1 (fácil) a 5 (muy difícil); validado en DB con CHECK CONSTRAINT
    @Column(nullable = false)
    private int dificultad;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
