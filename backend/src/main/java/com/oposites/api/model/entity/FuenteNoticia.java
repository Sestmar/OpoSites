package com.oposites.api.model.entity;

import com.oposites.api.model.enums.TipoFuenteNoticia;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "fuentes_noticias")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FuenteNoticia {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nombre;

    @Column(nullable = false, length = 500)
    private String url;

    @Enumerated(EnumType.STRING)
    @Column(name = "tipo_fuente", nullable = false, length = 30)
    private TipoFuenteNoticia tipoFuente;

    // Nullable: null = fuente global no asociada a una oposición concreta
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "rama_id")
    private RamaOposicion rama;

    @Column(nullable = false)
    @Builder.Default
    private boolean activa = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
