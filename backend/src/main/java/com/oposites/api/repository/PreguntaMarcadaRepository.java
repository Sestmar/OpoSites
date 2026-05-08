package com.oposites.api.repository;

import com.oposites.api.model.entity.PreguntaMarcada;
import com.oposites.api.model.entity.PreguntaMarcadaId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PreguntaMarcadaRepository extends JpaRepository<PreguntaMarcada, PreguntaMarcadaId> {

    /**
     * Cuenta las preguntas marcadas del usuario para una rama concreta.
     * Si ramaId es null, cuenta todas las marcadas sin filtrar por rama.
     */
    @Query(nativeQuery = true, value = """
            SELECT COUNT(*) FROM preguntas_marcadas pm
            JOIN preguntas p ON p.id = pm.pregunta_id
            JOIN temas t ON t.id = p.tema_id
            WHERE pm.usuario_id = :usuarioId
              AND (:ramaId IS NULL OR t.rama_id = :ramaId)
            """)
    long countByUsuarioIdAndRamaId(@Param("usuarioId") Long usuarioId,
                                   @Param("ramaId") Long ramaId);

    /**
     * Elimina la marca de la pregunta para el usuario dado.
     * Idempotente — no lanza error si no existía.
     */
    @Modifying
    @Query(nativeQuery = true, value = """
            DELETE FROM preguntas_marcadas
            WHERE usuario_id = :usuarioId AND pregunta_id = :preguntaId
            """)
    void deleteByUsuarioIdAndPreguntaId(@Param("usuarioId") Long usuarioId,
                                         @Param("preguntaId") Long preguntaId);
}
