package com.oposites.api.repository;

import com.oposites.api.model.entity.NoticiaConvocatoria;
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
              AND (:tipo IS NULL OR n.tipo = :tipo)
            ORDER BY n.fechaPublicacion DESC
            """)
    Page<NoticiaConvocatoria> findFiltered(
            @Param("ramaId") Long ramaId,
            @Param("tipo") TipoNoticia tipo,
            Pageable pageable);

    // Solo noticias globales (usuario sin rama principal asignada)
    @Query("""
            SELECT n FROM NoticiaConvocatoria n
            WHERE n.rama IS NULL
              AND n.active = true
              AND (:tipo IS NULL OR n.tipo = :tipo)
            ORDER BY n.fechaPublicacion DESC
            """)
    Page<NoticiaConvocatoria> findGlobalFiltered(
            @Param("tipo") TipoNoticia tipo,
            Pageable pageable);

    Optional<NoticiaConvocatoria> findByIdAndActiveTrue(Long id);
}
