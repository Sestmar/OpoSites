-- ──────────────────────────────────────────────────────────────────────────────
-- V5 — Plan de estudio: tabla plan_tareas
-- ──────────────────────────────────────────────────────────────────────────────

CREATE TABLE plan_tareas (
    id            BIGSERIAL PRIMARY KEY,
    usuario_id    BIGINT      NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    tipo          VARCHAR(20) NOT NULL CHECK (tipo IN ('TEST', 'REPASO', 'SIMULACRO')),
    tema_id       BIGINT REFERENCES temas(id) ON DELETE SET NULL,
    simulacro_id  BIGINT REFERENCES simulacros(id) ON DELETE SET NULL,
    fecha         DATE        NOT NULL,
    completada    BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- Consulta más frecuente: tareas del usuario para un día concreto
CREATE INDEX idx_plan_tareas_usuario_fecha ON plan_tareas(usuario_id, fecha);
