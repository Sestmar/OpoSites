package com.oposites.api.model.entity;

import com.oposites.api.model.enums.TipoNoticia;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "noticias_convocatorias")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NoticiaConvocatoria {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Nullable: null = noticia global (visible para todos los usuarios)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "rama_id")
    private RamaOposicion rama;

    @Column(nullable = false)
    private String titulo;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String contenido;

    @Column(name = "url_externa", length = 500)
    private String urlExterna;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private TipoNoticia tipo;

    @Column(name = "fecha_publicacion", nullable = false)
    private LocalDateTime fechaPublicacion;

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
