package com.oposites.api.model.chat;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Snapshot de un tema débil del usuario para el system prompt del chat IA.
 * Incluye nombre y % de acierto para que la IA tenga contexto cuantitativo real.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TemaDebilInfo {

    private String nombre;

    // Porcentaje de acierto sobre el total de respuestas del usuario en este tema (0-100, 1 decimal)
    private double porcentajeAcierto;
}
