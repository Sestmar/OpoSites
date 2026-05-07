package com.oposites.api.repository;

import com.oposites.api.model.entity.NoticiaLeida;
import com.oposites.api.model.entity.NoticiaLeidaId;
import com.oposites.api.model.enums.EstadoEditorialNoticia;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Set;

public interface NoticiaLeidaRepository extends JpaRepository<NoticiaLeida, NoticiaLeidaId> {

    @Query("SELECT nl.id.noticiaId FROM NoticiaLeida nl WHERE nl.id.usuarioId = :usuarioId")
    Set<Long> findNoticiaIdsByUsuarioId(@Param("usuarioId") Long usuarioId);

    /** Cuántas noticias leídas coinciden con el filtro rama+globales (misma lógica que findFiltered). */
    @Query("SELECT COUNT(nl) FROM NoticiaLeida nl " +
           "WHERE nl.id.usuarioId = :usuarioId " +
           "AND nl.noticia.active = true " +
           "AND nl.noticia.estadoEditorial = :estado " +
           "AND (nl.noticia.rama.id = :ramaId OR nl.noticia.rama IS NULL)")
    long countLeidasFiltradas(@Param("usuarioId") Long usuarioId,
                              @Param("ramaId") Long ramaId,
                              @Param("estado") EstadoEditorialNoticia estado);

    /** Cuántas noticias leídas son globales (rama IS NULL), equivalente a findGlobalFiltered. */
    @Query("SELECT COUNT(nl) FROM NoticiaLeida nl " +
           "WHERE nl.id.usuarioId = :usuarioId " +
           "AND nl.noticia.active = true " +
           "AND nl.noticia.estadoEditorial = :estado " +
           "AND nl.noticia.rama IS NULL")
    long countLeidasGlobal(@Param("usuarioId") Long usuarioId,
                           @Param("estado") EstadoEditorialNoticia estado);
}
