package com.oposites.api.model.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "documentos")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Documento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    @Column(nullable = false, length = 255)
    private String nombre;

    // 'PDF' | 'TXT'
    @Column(name = "tipo_archivo", nullable = false, length = 10)
    private String tipoArchivo;

    @Column(name = "ruta_fisica", nullable = false, length = 500)
    private String rutaFisica;

    // Texto extraído del documento (truncado a MAX_CHARS si es muy largo)
    @Column(name = "texto_extraido", columnDefinition = "TEXT")
    private String textoExtraido;

    @Column(name = "tamano_bytes", nullable = false)
    private long tamanoBytes;

    @Column(name = "creado_en", nullable = false, updatable = false)
    private LocalDateTime creadoEn;

    @PrePersist
    protected void onCreate() {
        this.creadoEn = LocalDateTime.now();
    }
}
