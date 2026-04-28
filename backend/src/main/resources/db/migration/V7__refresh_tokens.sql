-- V7: Tabla de refresh tokens para revocación y rotación server-side

CREATE TABLE refresh_tokens (
    id          BIGSERIAL PRIMARY KEY,
    token_hash  VARCHAR(64)  UNIQUE NOT NULL,      -- SHA-256 del JWT (hex lowercase)
    usuario_id  BIGINT       NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    expires_at  TIMESTAMP    NOT NULL,
    revocado    BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_usuario  ON refresh_tokens(usuario_id);
CREATE INDEX idx_refresh_tokens_hash     ON refresh_tokens(token_hash);
-- Índice parcial: solo los tokens activos necesitan búsqueda frecuente
CREATE INDEX idx_refresh_tokens_activos  ON refresh_tokens(token_hash) WHERE revocado = FALSE;
