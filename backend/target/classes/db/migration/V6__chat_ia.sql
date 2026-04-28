-- ──────────────────────────────────────────────────────────────────────────────
-- V6 — Chat IA: conversaciones y mensajes
-- ──────────────────────────────────────────────────────────────────────────────

CREATE TABLE chat_conversaciones (
    id          BIGSERIAL PRIMARY KEY,
    usuario_id  BIGINT    NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    rama_id     BIGINT    REFERENCES ramas_oposiciones(id) ON DELETE SET NULL,
    contexto    JSONB     NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE chat_mensajes (
    id                BIGSERIAL    PRIMARY KEY,
    conversacion_id   BIGINT       NOT NULL REFERENCES chat_conversaciones(id) ON DELETE CASCADE,
    es_ia             BOOLEAN      NOT NULL,
    mensaje           TEXT         NOT NULL,
    created_at        TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Consulta más frecuente: mensajes de una conversación en orden cronológico
CREATE INDEX idx_chat_mensajes_conv_fecha ON chat_mensajes(conversacion_id, created_at);
