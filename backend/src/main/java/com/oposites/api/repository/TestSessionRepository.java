package com.oposites.api.repository;

import com.oposites.api.model.entity.TestSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface TestSessionRepository extends JpaRepository<TestSession, Long> {

    Optional<TestSession> findByIdAndUsuarioId(Long id, Long usuarioId);

    /**
     * Días distintos en que el usuario completó al menos una sesión.
     * Devueltos en orden descendente para calcular racha.
     */
    @Query(nativeQuery = true, value = """
            SELECT DISTINCT DATE(fecha_fin)
            FROM test_sessions
            WHERE usuario_id = :usuarioId
              AND estado = 'COMPLETADO'
              AND fecha_fin IS NOT NULL
            ORDER BY DATE(fecha_fin) DESC
            """)
    List<java.sql.Date> findDiasEstudiados(@Param("usuarioId") Long usuarioId);

    /**
     * Evolución semanal de nota media y tests completados.
     * Retorna filas [semana:Timestamp, notaMedia:Double, testsCompletados:Long].
     */
    @Query(nativeQuery = true, value = """
            SELECT DATE_TRUNC('week', fecha_fin) AS semana,
                   AVG(nota)                     AS nota_media,
                   COUNT(*)                      AS tests
            FROM test_sessions
            WHERE usuario_id = :usuarioId
              AND estado = 'COMPLETADO'
              AND fecha_fin >= :desde
            GROUP BY DATE_TRUNC('week', fecha_fin)
            ORDER BY semana ASC
            """)
    List<Object[]> findEvolucionSemanal(@Param("usuarioId") Long usuarioId,
                                        @Param("desde") java.time.LocalDateTime desde);
}
