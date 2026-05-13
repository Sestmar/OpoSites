package com.oposites.api.repository;

import com.oposites.api.model.entity.SesionRepaso;
import com.oposites.api.model.enums.EstadoSesionRepaso;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface SesionRepasoRepository extends JpaRepository<SesionRepaso, Long> {

    Optional<SesionRepaso> findByIdAndUsuarioId(Long id, Long usuarioId);

    /** Busca la sesión EN_CURSO más reciente del usuario (para recuperarla si el estado local se perdió). */
    Optional<SesionRepaso> findFirstByUsuarioIdAndEstadoOrderByCreatedAtDesc(Long usuarioId, EstadoSesionRepaso estado);

    /** Expira sesiones EN_CURSO anteriores del usuario antes de crear una nueva. */
    @Modifying
    @Query("""
            UPDATE SesionRepaso s SET s.estado = :completada
            WHERE s.usuario.id = :usuarioId AND s.estado = :enCurso
            """)
    void expirarSesionesActivas(@Param("usuarioId") Long usuarioId,
                                @Param("enCurso") EstadoSesionRepaso enCurso,
                                @Param("completada") EstadoSesionRepaso completada);
}
