package com.oposites.api.model.entity;

import com.oposites.api.model.enums.Role;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "usuarios")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(name = "google_id")
    private String googleId;

    @Column(nullable = false)
    private String nombre;

    private String ciudad;

    // Nullable: usuarios de Google no tienen contraseña
    @Column(name = "password_hash")
    private String passwordHash;

    @Column(name = "fecha_registro", nullable = false)
    private LocalDateTime fechaRegistro;

    // FK a ramas_oposiciones: se añade en V2 (sin constraint por ahora)
    @Column(name = "rama_principal_id")
    private Long ramaPrincipalId;

    @Column(name = "fecha_examen_objetivo")
    private LocalDate fechaExamenObjetivo;

    @Column(name = "plan_manual", columnDefinition = "jsonb")
    private String planManual;

    @Column(name = "enabled_chat_private", nullable = false)
    @Builder.Default
    private boolean enabledChatPrivate = false;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private Role role = Role.USER;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        this.createdAt = now;
        this.updatedAt = now;
        if (this.fechaRegistro == null) {
            this.fechaRegistro = now;
        }
        if (this.role == null) {
            this.role = Role.USER;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
