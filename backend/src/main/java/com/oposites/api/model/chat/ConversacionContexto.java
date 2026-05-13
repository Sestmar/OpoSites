package com.oposites.api.model.chat;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.oposites.api.model.enums.ChatModo;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * POJO serializado como JSON en el campo contexto (JSONB) de chat_conversaciones.
 * Desde 1.5, se recalcula en cada envío de mensaje (no se lee el JSONB congelado).
 * El JSONB persiste solo para la vista de lista de conversaciones.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConversacionContexto {

    private String nombreRama;

    // ISO date (ej. "2026-09-15"), null si el usuario no tiene fecha configurada
    private String fechaExamen;

    // Días exactos hasta el examen, calculados en buildContexto(). Null si no hay fecha.
    private Integer diasHastaExamen;

    // Nombres de los top-3 temas más débiles del usuario (mantenido para compatibilidad con la lista)
    private List<String> temasDebiles;

    // 1.1 — Temas débiles con % de acierto real. Sustituye a temasDebiles en el system prompt.
    private List<TemaDebilInfo> temasDebilesDetalle;

    // 1.1 — Métricas globales de rendimiento del usuario
    private int totalRespuestas;
    private double porcentajeAciertoGlobal;   // 0-100, redondeado a 1 decimal
    private int respuestasEstaSemana;

    // 1.1 — Métricas de actividad reciente
    private int diasActivosEstaSemana;               // días distintos con actividad en la semana actual
    private Double porcentajeAciertoEstaSemana;      // null si no hay actividad esta semana
    private Integer diasDesdeUltimaActividad;         // null si el usuario nunca ha practicado

    // Convocatorias y noticias recientes de la rama del usuario (inyectadas en el system prompt)
    private List<String> convocatorias;

    // 1.4 — Nombre del documento anclado (persiste en JSONB para mostrar en la lista)
    private String nombreDocumento;

    // 1.4 — Contenido documental resuelto en runtime: no se persiste en JSONB.
    // Se llena en buildContexto() y se consume en buildSystemPrompt().
    @JsonIgnore
    private String contenidoDocumental;

    @JsonIgnore
    private boolean contenidoDocumentalEsExtracto;

    // 1.6 — Modo de la conversación: transient, se inyecta en buildContexto()
    @JsonIgnore
    private ChatModo modo;
}
