package com.oposites.api.repository;

import com.oposites.api.model.entity.CalendarioEvento;
import com.oposites.api.model.enums.TipoEvento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface CalendarioEventoRepository extends JpaRepository<CalendarioEvento, Long> {

    @Query("""
            SELECT e FROM CalendarioEvento e
            WHERE e.usuario.id = :usuarioId
              AND e.fechaInicio BETWEEN :desde AND :hasta
              AND (:tipo IS NULL OR e.tipo = :tipo)
            ORDER BY e.fechaInicio ASC
            """)
    List<CalendarioEvento> findFiltered(
            @Param("usuarioId") Long usuarioId,
            @Param("desde") LocalDateTime desde,
            @Param("hasta") LocalDateTime hasta,
            @Param("tipo") TipoEvento tipo);

    Optional<CalendarioEvento> findByIdAndUsuarioId(Long id, Long usuarioId);
}
