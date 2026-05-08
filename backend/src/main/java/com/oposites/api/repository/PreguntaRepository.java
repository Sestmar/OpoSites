package com.oposites.api.repository;

import com.oposites.api.model.entity.Pregunta;
import com.oposites.api.model.enums.TipoPregunta;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface PreguntaRepository extends JpaRepository<Pregunta, Long> {

    /**
     * Lista preguntas de un tema con filtros opcionales de tipo y dificultad.
     * Cuando tipo o dificultad son null, la condición se ignora.
     */
    @Query("""
            SELECT p FROM Pregunta p
            WHERE p.tema.id = :temaId
              AND (:tipo IS NULL OR p.tipo = :tipo)
              AND (:dificultad IS NULL OR p.dificultad = :dificultad)
            ORDER BY p.dificultad ASC, p.id ASC
            """)
    List<Pregunta> findByTemaIdWithFilters(
            @Param("temaId") Long temaId,
            @Param("tipo") TipoPregunta tipo,
            @Param("dificultad") Integer dificultad,
            Pageable pageable);

    int countByTemaId(Long temaId);

    /**
     * Selección aleatoria de preguntas de los temas indicados.
     * Nativo PostgreSQL — usa ORDER BY RANDOM() para aleatoriedad real.
     * dificultad puede ser null (sin filtro).
     */
    @Query(nativeQuery = true, value = """
            SELECT * FROM preguntas
            WHERE tema_id IN (:temaIds)
              AND (:dificultad IS NULL OR dificultad <= :dificultad)
            ORDER BY RANDOM()
            LIMIT :cantidad
            """)
    List<Pregunta> findRandomByTemaIds(@Param("temaIds") List<Long> temaIds,
                                       @Param("dificultad") Integer dificultad,
                                       @Param("cantidad") int cantidad);

    /**
     * Carga preguntas con su tema en un solo JOIN para evitar N+1
     * al calcular analisisPorTema en simulacros.
     */
    @Query("SELECT p FROM Pregunta p JOIN FETCH p.tema WHERE p.id IN :ids")
    List<Pregunta> findAllByIdWithTema(@Param("ids") List<Long> ids);
}
