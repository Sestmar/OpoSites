package com.oposites.api.repository;

import com.oposites.api.model.entity.NoticiaLeida;
import com.oposites.api.model.entity.NoticiaLeidaId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Set;

public interface NoticiaLeidaRepository extends JpaRepository<NoticiaLeida, NoticiaLeidaId> {

    @Query("SELECT nl.id.noticiaId FROM NoticiaLeida nl WHERE nl.id.usuarioId = :usuarioId")
    Set<Long> findNoticiaIdsByUsuarioId(@Param("usuarioId") Long usuarioId);
}
