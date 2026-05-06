package com.oposites.api.repository;

import com.oposites.api.model.entity.NoticiaConvocatoria;
import com.oposites.api.model.enums.EstadoEditorialNoticia;
import com.oposites.api.model.enums.TipoNoticia;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface NoticiaConvocatoriaRepository extends JpaRepository<NoticiaConvocatoria, Long> {

    // Noticias de una rama específica + noticias globales (rama IS NULL).
    // Usar cuando ramaId != null. Los conteos de countFiltered usan la misma condición.
    @Query("""
            SELECT n FROM NoticiaConvocatoria n
            WHERE (n.rama.id = :ramaId OR n.rama IS NULL)
              AND n.active = true
              AND n.estadoEditorial = :estado
              AND (:tipo IS NULL OR n.tipo = :tipo)
              AND (:q IS NULL OR LOWER(n.titulo) LIKE LOWER(CONCAT('%', CAST(:q AS string), '%')))
            ORDER BY n.fechaPublicacion DESC
            """)
    Page<NoticiaConvocatoria> findFiltered(
            @Param("ramaId") Long ramaId,
            @Param("tipo") TipoNoticia tipo,
            @Param("estado") EstadoEditorialNoticia estado,
            @Param("q") String q,
            Pageable pageable);

    // Solo noticias globales (rama IS NULL). Usar cuando ramaId = null ("General").
    // Los conteos de countGlobalFiltered usan la misma condición.
    @Query("""
            SELECT n FROM NoticiaConvocatoria n
            WHERE n.rama IS NULL
              AND n.active = true
              AND n.estadoEditorial = :estado
              AND (:tipo IS NULL OR n.tipo = :tipo)
              AND (:q IS NULL OR LOWER(n.titulo) LIKE LOWER(CONCAT('%', CAST(:q AS string), '%')))
            ORDER BY n.fechaPublicacion DESC
            """)
    Page<NoticiaConvocatoria> findGlobalFiltered(
            @Param("tipo") TipoNoticia tipo,
            @Param("estado") EstadoEditorialNoticia estado,
            @Param("q") String q,
            Pageable pageable);

    Optional<NoticiaConvocatoria> findByIdAndActiveTrueAndEstadoEditorial(Long id, EstadoEditorialNoticia estadoEditorial);

    @Query("""
            SELECT COUNT(n) FROM NoticiaConvocatoria n
            WHERE (n.rama.id = :ramaId OR n.rama IS NULL)
              AND n.active = true
              AND n.estadoEditorial = :estado
              AND (:tipo IS NULL OR n.tipo = :tipo)
            """)
    long countFiltered(@Param("ramaId") Long ramaId,
                       @Param("estado") EstadoEditorialNoticia estado,
                       @Param("tipo") TipoNoticia tipo);

    @Query("""
            SELECT COUNT(n) FROM NoticiaConvocatoria n
            WHERE n.rama IS NULL
              AND n.active = true
              AND n.estadoEditorial = :estado
              AND (:tipo IS NULL OR n.tipo = :tipo)
            """)
    long countGlobalFiltered(@Param("estado") EstadoEditorialNoticia estado,
                              @Param("tipo") TipoNoticia tipo);

    Page<NoticiaConvocatoria> findByEstadoEditorialOrderByFechaPublicacionDesc(
            EstadoEditorialNoticia estadoEditorial,
            Pageable pageable);

    @Query("""
            SELECT COUNT(n) > 0 FROM NoticiaConvocatoria n
            WHERE n.urlExterna IS NOT NULL
              AND lower(n.urlExterna) = lower(:url)
              AND n.fechaPublicacion = :fechaPublicacion
            """)
    boolean existsByUrlAndFechaPublicacion(@Param("url") String url, @Param("fechaPublicacion") java.time.LocalDateTime fechaPublicacion);

    @Query("""
            SELECT COUNT(n) > 0 FROM NoticiaConvocatoria n
            WHERE lower(n.titulo) = lower(:titulo)
              AND n.fechaPublicacion = :fechaPublicacion
            """)
    boolean existsByTituloAndFechaPublicacion(@Param("titulo") String titulo, @Param("fechaPublicacion") java.time.LocalDateTime fechaPublicacion);
}
