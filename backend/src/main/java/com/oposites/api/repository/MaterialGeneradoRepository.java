package com.oposites.api.repository;

import com.oposites.api.model.entity.MaterialGenerado;
import com.oposites.api.model.enums.TipoMaterial;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MaterialGeneradoRepository extends JpaRepository<MaterialGenerado, Long> {

    List<MaterialGenerado> findByDocumentoIdOrderByCreadoEnDesc(Long documentoId);

    // 1.4 — Busca el RESUMEN más reciente de un documento para usarlo como contexto del chat
    Optional<MaterialGenerado> findTopByDocumentoIdAndTipoOrderByCreadoEnDesc(Long documentoId, TipoMaterial tipo);
}
