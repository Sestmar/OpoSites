CREATE TABLE preguntas_marcadas (
    usuario_id  BIGINT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    pregunta_id BIGINT NOT NULL REFERENCES preguntas(id) ON DELETE CASCADE,
    marcada_en  TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (usuario_id, pregunta_id)
);

CREATE INDEX idx_pm_usuario ON preguntas_marcadas(usuario_id);
