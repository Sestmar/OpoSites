package com.oposites.api.repository;

import com.oposites.api.model.entity.RamaOposicion;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface RamaOposicionRepository extends JpaRepository<RamaOposicion, Long> {

    List<RamaOposicion> findByActiveTrueOrderByNombre();

    Optional<RamaOposicion> findByIdAndActiveTrue(Long id);
}
