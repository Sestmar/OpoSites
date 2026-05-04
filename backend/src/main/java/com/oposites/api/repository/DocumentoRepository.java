package com.oposites.api.repository;

import com.oposites.api.model.entity.Documento;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface DocumentoRepository extends JpaRepository<Documento, Long> {

    List<Documento> findByUsuarioIdOrderByCreadoEnDesc(Long usuarioId);

    Optional<Documento> findByIdAndUsuarioId(Long id, Long usuarioId);
}
