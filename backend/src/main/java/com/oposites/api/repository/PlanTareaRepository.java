package com.oposites.api.repository;

import com.oposites.api.model.entity.PlanTarea;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface PlanTareaRepository extends JpaRepository<PlanTarea, Long> {

    List<PlanTarea> findByUsuarioIdAndFechaOrderByCreatedAtAsc(Long usuarioId, LocalDate fecha);

    List<PlanTarea> findByUsuarioIdAndFechaBetweenOrderByFechaAscCreatedAtAsc(Long usuarioId, LocalDate desde, LocalDate hasta);

    Optional<PlanTarea> findByIdAndUsuarioId(Long id, Long usuarioId);

    boolean existsByUsuarioIdAndFecha(Long usuarioId, LocalDate fecha);

    // Borra las tareas incompletas desde hoy en adelante (para regenerar el plan)
    @Modifying
    @Query("""
            DELETE FROM PlanTarea t
            WHERE t.usuario.id = :usuarioId
              AND t.fecha >= :desde
              AND t.completada = false
            """)
    void deleteIncompletsDesde(@Param("usuarioId") Long usuarioId,
                               @Param("desde") LocalDate desde);
}
