package com.oposites.api.model.chat;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * POJO serializado como JSON en el campo contexto (JSONB) de chat_conversaciones.
 * Se persiste al crear la conversación y se reutiliza para construir el system prompt
 * en cada llamada al LLM, sin recalcularlo en cada mensaje.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConversacionContexto {

    private String nombreRama;

    // ISO date (ej. "2026-09-15"), null si el usuario no tiene fecha configurada
    private String fechaExamen;

    // Nombres de los top-3 temas más débiles del usuario
    private List<String> temasDebiles;
}
