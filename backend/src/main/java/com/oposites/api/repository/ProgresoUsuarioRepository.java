package com.oposites.api.repository;

import com.oposites.api.model.entity.ProgresoUsuario;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

public interface ProgresoUsuarioRepository extends JpaRepository<ProgresoUsuario, Long> {

    long countByUsuarioId(Long usuarioId);

    long countByUsuarioIdAndCorrectoTrue(Long usuarioId);

    /**
     * IDs distintos de preguntas falladas por el usuario.
     * Filtros opcionales por rama y tema.
     */
    @Query("""
            SELECT DISTINCT p.pregunta.id
            FROM ProgresoUsuario p
            WHERE p.usuario.id = :usuarioId
              AND p.correcto = false
              AND (:ramaId IS NULL OR p.pregunta.tema.rama.id = :ramaId)
              AND (:temaId IS NULL OR p.pregunta.tema.id = :temaId)
            ORDER BY p.pregunta.id ASC
            """)
    List<Long> findPreguntaIdsFalladas(@Param("usuarioId") Long usuarioId,
                                       @Param("ramaId") Long ramaId,
                                       @Param("temaId") Long temaId,
                                       Pageable pageable);

    /**
     * Estadísticas de respuestas agrupadas por tema.
     * Retorna filas [temaId:Long, total:Long, correctas:Long].
     */
    @Query("""
            SELECT p.pregunta.tema.id,
                   COUNT(p),
                   SUM(CASE WHEN p.correcto = true THEN 1 ELSE 0 END)
            FROM ProgresoUsuario p
            WHERE p.usuario.id = :usuarioId
              AND (:ramaId IS NULL OR p.pregunta.tema.rama.id = :ramaId)
            GROUP BY p.pregunta.tema.id
            ORDER BY p.pregunta.tema.id ASC
            """)
    List<Object[]> findEstadisticasPorTema(@Param("usuarioId") Long usuarioId,
                                           @Param("ramaId") Long ramaId);

    /**
     * IDs de temas ordenados de más débil a más fuerte (menor % acierto primero).
     * Usado por PlanService para seleccionar temas prioritarios del plan diario.
     */
    @Query("""
            SELECT p.pregunta.tema.id
            FROM ProgresoUsuario p
            WHERE p.usuario.id = :usuarioId
              AND p.pregunta.tema.rama.id = :ramaId
            GROUP BY p.pregunta.tema.id
            ORDER BY (SUM(CASE WHEN p.correcto = true THEN 1.0 ELSE 0.0 END) / COUNT(p)) ASC
            """)
    List<Long> findTemaIdsOrdenadosPorDebilidad(@Param("usuarioId") Long usuarioId,
                                                @Param("ramaId") Long ramaId,
                                                Pageable pageable);

    /**
     * Evolución semanal de aciertos para un tema específico.
     * Retorna filas [semanaInicio:Timestamp, total:Long, correctas:Long].
     * Solo incluye semanas con al menos una respuesta desde [desde].
     */
    @Query(value = """
            SELECT DATE_TRUNC('week', pu.fecha_respuesta) AS semana,
                   COUNT(*)                               AS total,
                   SUM(CASE WHEN pu.correcto THEN 1 ELSE 0 END) AS correctas
            FROM   progreso_usuario pu
            JOIN   preguntas pr ON pu.pregunta_id = pr.id
            WHERE  pu.usuario_id        = :usuarioId
              AND  pr.tema_id           = :temaId
              AND  pu.fecha_respuesta  >= :desde
            GROUP  BY DATE_TRUNC('week', pu.fecha_respuesta)
            ORDER  BY 1 ASC
            """, nativeQuery = true)
    List<Object[]> findEvolucionSemanalByTema(@Param("usuarioId") Long usuarioId,
                                              @Param("temaId") Long temaId,
                                              @Param("desde") LocalDateTime desde);

    /**
     * IDs de temas que el usuario ya ha practicado (al menos una respuesta).
     * Usado por PlanService para evitar asignar temas sin datos como "temas débiles".
     */
    @Query("""
            SELECT DISTINCT p.pregunta.tema.id
            FROM ProgresoUsuario p
            WHERE p.usuario.id = :usuarioId
              AND p.pregunta.tema.rama.id = :ramaId
            """)
    Set<Long> findTemaIdsPracticados(@Param("usuarioId") Long usuarioId,
                                     @Param("ramaId") Long ramaId);
}
