package com.oposites.api.repository;

import com.oposites.api.model.entity.Tema;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface TemaRepository extends JpaRepository<Tema, Long> {

    List<Tema> findByRamaIdOrderByOrden(Long ramaId);

    boolean existsByRamaId(Long ramaId);

    @Query("SELECT t.id FROM Tema t WHERE t.rama.id = :ramaId")
    List<Long> findIdsByRamaId(@Param("ramaId") Long ramaId);
}
