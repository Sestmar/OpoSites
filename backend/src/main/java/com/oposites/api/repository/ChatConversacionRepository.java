package com.oposites.api.repository;

import com.oposites.api.model.entity.ChatConversacion;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ChatConversacionRepository extends JpaRepository<ChatConversacion, Long> {

    List<ChatConversacion> findByUsuarioIdOrderByCreatedAtDesc(Long usuarioId);

    Optional<ChatConversacion> findByIdAndUsuarioId(Long id, Long usuarioId);
}
