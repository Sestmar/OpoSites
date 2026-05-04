package com.oposites.api.model.entity;

import com.oposites.api.model.enums.TipoMaterial;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "materiales_generados")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MaterialGenerado {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "documento_id", nullable = false)
    private Documento documento;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 50)
    private TipoMaterial tipo;

    // JSON string generado por IA (estructura varía según el tipo)
    @Column(columnDefinition = "TEXT", nullable = false)
    private String contenido;

    @Column(name = "creado_en", nullable = false, updatable = false)
    private LocalDateTime creadoEn;

    @PrePersist
    protected void onCreate() {
        this.creadoEn = LocalDateTime.now();
    }
}
