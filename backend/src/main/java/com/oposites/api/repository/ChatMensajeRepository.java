package com.oposites.api.repository;

import com.oposites.api.model.entity.ChatMensaje;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ChatMensajeRepository extends JpaRepository<ChatMensaje, Long> {

    // Historial completo para mostrar al usuario en la UI (orden cronológico)
    List<ChatMensaje> findByConversacionIdOrderByCreatedAtAsc(Long conversacionId);

    // Ventana de contexto para el LLM: últimos N mensajes (se revierten a ASC en el servicio)
    List<ChatMensaje> findTop20ByConversacionIdOrderByCreatedAtDesc(Long conversacionId);
}
