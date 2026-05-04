package com.oposites.api.model.entity;

import com.oposites.api.model.converter.JsonStringListConverter;
import jakarta.persistence.*;
import lombok.*;

import java.util.List;

@Entity
@Table(name = "documento_test_preguntas")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DocumentoTestPregunta {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "test_id", nullable = false)
    private DocumentoTest test;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String enunciado;

    @Convert(converter = JsonStringListConverter.class)
    @Column(columnDefinition = "TEXT", nullable = false)
    private List<String> opciones;

    @Column(name = "respuesta_correcta", nullable = false)
    private int respuestaCorrecta;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String explicacion;

    @Column(nullable = false)
    private int orden;
}
