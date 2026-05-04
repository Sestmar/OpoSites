package com.oposites.api.repository;

import com.oposites.api.model.entity.MaterialGenerado;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MaterialGeneradoRepository extends JpaRepository<MaterialGenerado, Long> {

    List<MaterialGenerado> findByDocumentoIdOrderByCreadoEnDesc(Long documentoId);
}
