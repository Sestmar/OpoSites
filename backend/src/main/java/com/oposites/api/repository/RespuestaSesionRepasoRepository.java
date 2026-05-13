package com.oposites.api.repository;

import com.oposites.api.model.entity.RespuestaSesionRepaso;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RespuestaSesionRepasoRepository extends JpaRepository<RespuestaSesionRepaso, Long> {

    List<RespuestaSesionRepaso> findBySesionRepasoIdOrderByPreguntaIndexAsc(Long sesionRepasoId);

    long countBySesionRepasoId(Long sesionRepasoId);

    boolean existsBySesionRepasoIdAndPreguntaIndex(Long sesionRepasoId, int preguntaIndex);
}
