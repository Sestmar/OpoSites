package com.oposites.api.repository;

import com.oposites.api.model.entity.NoticiaLeida;
import com.oposites.api.model.entity.NoticiaLeidaId;
import com.oposites.api.model.enums.EstadoEditorialNoticia;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
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

    /**
     * Inserta en bloque todas las noticias no leídas de la rama X + globales
     * para el usuario indicado. Equivale a llamar marcarLeida() individualmente
     * pero en una sola query. Solo inserta filas que aún no existan.
     */
    @Modifying
    @Query(value = """
            INSERT INTO noticia_leida (noticia_id, usuario_id, leida_at)
            SELECT n.id, :usuarioId, NOW()
            FROM noticias_convocatorias n
            WHERE n.active = true
              AND n.estado_editorial = 'PUBLICADA'
              AND (n.rama_id = :ramaId OR n.rama_id IS NULL)
              AND NOT EXISTS (
                  SELECT 1 FROM noticia_leida nl
                  WHERE nl.noticia_id = n.id AND nl.usuario_id = :usuarioId
              )
            """, nativeQuery = true)
    void insertarLeidasPorRama(@Param("usuarioId") Long usuarioId,
                               @Param("ramaId") Long ramaId);

    /** Versión para ramaId = null: solo noticias globales. */
    @Modifying
    @Query(value = """
            INSERT INTO noticia_leida (noticia_id, usuario_id, leida_at)
            SELECT n.id, :usuarioId, NOW()
            FROM noticias_convocatorias n
            WHERE n.active = true
              AND n.estado_editorial = 'PUBLICADA'
              AND n.rama_id IS NULL
              AND NOT EXISTS (
                  SELECT 1 FROM noticia_leida nl
                  WHERE nl.noticia_id = n.id AND nl.usuario_id = :usuarioId
              )
            """, nativeQuery = true)
    void insertarLeidasGlobal(@Param("usuarioId") Long usuarioId);
}
