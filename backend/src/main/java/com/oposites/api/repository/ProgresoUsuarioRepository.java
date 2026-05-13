package com.oposites.api.repository;

import com.oposites.api.model.entity.ProgresoUsuario;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.Set;

public interface ProgresoUsuarioRepository extends JpaRepository<ProgresoUsuario, Long> {

    long countByUsuarioId(Long usuarioId);

    long countByUsuarioIdAndCorrectoTrue(Long usuarioId);

    // 1.1 — Respuestas practicadas desde una fecha dada (proxy de actividad reciente)
    long countByUsuarioIdAndFechaRespuestaAfter(Long usuarioId, java.time.LocalDateTime desde);

    // 1.1 — Respuestas correctas desde una fecha (para calcular % de acierto semanal)
    long countByUsuarioIdAndCorrectoTrueAndFechaRespuestaAfter(Long usuarioId, LocalDateTime desde);

    // 1.1 — Fecha de la última respuesta del usuario (para días de inactividad)
    @Query("SELECT MAX(p.fechaRespuesta) FROM ProgresoUsuario p WHERE p.usuario.id = :usuarioId")
    Optional<LocalDateTime> findUltimaActividad(@Param("usuarioId") Long usuarioId);

    // 1.1 — Días distintos con actividad desde una fecha (proxy de racha semanal)
    @Query(value = """
            SELECT COUNT(DISTINCT DATE(fecha_respuesta))
            FROM progreso_usuario
            WHERE usuario_id = :usuarioId
              AND fecha_respuesta >= :desde
            """, nativeQuery = true)
    Long countDiasActivosDesde(@Param("usuarioId") Long usuarioId,
                               @Param("desde") LocalDateTime desde);

    /**
     * IDs distintos de preguntas falladas por el usuario.
     * Filtros opcionales por rama y tema.
     */
    @Query("""
            SELECT DISTINCT p.pregunta.id
            FROM ProgresoUsuario p
            WHERE p.usuario.id = :usuarioId
              AND p.pregunta IS NOT NULL
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
     * Incluye tanto respuestas de tests reales (via pregunta→tema) como de repaso IA (via tema_id directo).
     * Retorna filas [temaId:Long, total:Long, correctas:Long].
     */
    @Query(value = """
            SELECT COALESCE(pr.tema_id, pu.tema_id)        AS tema_id,
                   COUNT(*)                                 AS total,
                   SUM(CASE WHEN pu.correcto THEN 1 ELSE 0 END) AS correctas
            FROM   progreso_usuario pu
            LEFT   JOIN preguntas pr ON pu.pregunta_id = pr.id
            JOIN   temas t ON t.id = COALESCE(pr.tema_id, pu.tema_id)
            WHERE  pu.usuario_id = :usuarioId
              AND  (:ramaId IS NULL OR t.rama_id = :ramaId)
              AND  COALESCE(pr.tema_id, pu.tema_id) IS NOT NULL
            GROUP  BY COALESCE(pr.tema_id, pu.tema_id)
            ORDER  BY COALESCE(pr.tema_id, pu.tema_id) ASC
            """, nativeQuery = true)
    List<Object[]> findEstadisticasPorTema(@Param("usuarioId") Long usuarioId,
                                           @Param("ramaId") Long ramaId);

    /**
     * IDs de temas ordenados de más débil a más fuerte (menor % acierto primero).
     * Incluye respuestas de repaso IA. Usado por PlanService y SesionRepasoService.
     */
    @Query(value = """
            SELECT COALESCE(pr.tema_id, pu.tema_id) AS tema_id
            FROM   progreso_usuario pu
            LEFT   JOIN preguntas pr ON pu.pregunta_id = pr.id
            JOIN   temas t ON t.id = COALESCE(pr.tema_id, pu.tema_id)
            WHERE  pu.usuario_id = :usuarioId
              AND  t.rama_id = :ramaId
              AND  COALESCE(pr.tema_id, pu.tema_id) IS NOT NULL
            GROUP  BY COALESCE(pr.tema_id, pu.tema_id)
            ORDER  BY SUM(CASE WHEN pu.correcto THEN 1.0 ELSE 0.0 END) / COUNT(*) ASC
            """, nativeQuery = true)
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
