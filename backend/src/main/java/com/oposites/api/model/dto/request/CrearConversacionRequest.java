package com.oposites.api.model.dto.request;

import com.oposites.api.model.enums.ChatModo;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Body opcional del POST /chat/conversaciones.
 * documentoId: null → sin contexto documental.
 * modo: null → GENERAL por defecto.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CrearConversacionRequest {
    private Long documentoId;
    private ChatModo modo;
}
