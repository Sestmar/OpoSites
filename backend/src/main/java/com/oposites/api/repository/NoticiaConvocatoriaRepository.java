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

    // Noticias de una rama específica + noticias globales (rama IS NULL), con filtro opcional de tipo
    @Query("""
            SELECT n FROM NoticiaConvocatoria n
            WHERE (n.rama.id = :ramaId OR n.rama IS NULL)
              AND n.active = true
              AND n.estadoEditorial = :estado
              AND (:tipo IS NULL OR n.tipo = :tipo)
            ORDER BY n.fechaPublicacion DESC
            """)
    Page<NoticiaConvocatoria> findFiltered(
            @Param("ramaId") Long ramaId,
            @Param("tipo") TipoNoticia tipo,
            @Param("estado") EstadoEditorialNoticia estado,
            Pageable pageable);

    // Solo noticias globales (usuario sin rama principal asignada)
    @Query("""
            SELECT n FROM NoticiaConvocatoria n
            WHERE n.rama IS NULL
              AND n.active = true
              AND n.estadoEditorial = :estado
              AND (:tipo IS NULL OR n.tipo = :tipo)
            ORDER BY n.fechaPublicacion DESC
            """)
    Page<NoticiaConvocatoria> findGlobalFiltered(
            @Param("tipo") TipoNoticia tipo,
            @Param("estado") EstadoEditorialNoticia estado,
            Pageable pageable);

    Optional<NoticiaConvocatoria> findByIdAndActiveTrueAndEstadoEditorial(Long id, EstadoEditorialNoticia estadoEditorial);

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
