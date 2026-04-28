package com.oposites.api.repository;

import com.oposites.api.model.entity.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Optional;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {

    Optional<RefreshToken> findByTokenHash(String tokenHash);

    @Modifying
    @Query("""
            UPDATE RefreshToken r SET r.revocado = true
            WHERE r.usuario.id = :usuarioId AND r.revocado = false
            """)
    void revocarTodosDeUsuario(@Param("usuarioId") Long usuarioId);

    @Modifying
    void deleteByExpiresAtBefore(LocalDateTime dateTime);
}
