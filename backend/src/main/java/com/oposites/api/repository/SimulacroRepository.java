package com.oposites.api.repository;

import com.oposites.api.model.entity.Simulacro;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SimulacroRepository extends JpaRepository<Simulacro, Long> {

    List<Simulacro> findByRamaIdOrderByNombreAsc(Long ramaId);

    // Usado por PlanService para seleccionar el simulacro más reciente en modo intensivo
    List<Simulacro> findByRamaIdOrderByIdDesc(Long ramaId);
}
