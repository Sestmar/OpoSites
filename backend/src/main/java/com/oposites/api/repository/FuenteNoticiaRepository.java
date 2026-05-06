package com.oposites.api.repository;

import com.oposites.api.model.entity.FuenteNoticia;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FuenteNoticiaRepository extends JpaRepository<FuenteNoticia, Long> {

    List<FuenteNoticia> findByActivaTrueOrderByIdAsc();
}
