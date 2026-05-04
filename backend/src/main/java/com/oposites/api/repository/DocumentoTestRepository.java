package com.oposites.api.repository;

import com.oposites.api.model.entity.DocumentoTest;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface DocumentoTestRepository extends JpaRepository<DocumentoTest, Long> {

    Optional<DocumentoTest> findTopByDocumentoIdOrderByCreadoEnDesc(Long documentoId);
}
