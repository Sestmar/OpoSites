package com.oposites.api.model.entity;

import com.oposites.api.model.enums.TipoPlanTarea;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "plan_tareas")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PlanTarea {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TipoPlanTarea tipo;

    // Nullable: SIMULACRO no tiene tema; TEST/REPASO sí
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tema_id")
    private Tema tema;

    // Nullable: solo para tareas tipo SIMULACRO
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "simulacro_id")
    private Simulacro simulacro;

    @Column(nullable = false)
    private LocalDate fecha;

    @Column(nullable = false)
    @Builder.Default
    private boolean completada = false;

    /** Descripción personalizada para tareas manuales. Null en tareas generadas por IA. */
    @Column(name = "descripcion", length = 200)
    private String descripcion;

    /** True cuando la tarea fue creada manualmente por el usuario (no por la IA). */
    @Column(nullable = false)
    @Builder.Default
    private boolean manual = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
