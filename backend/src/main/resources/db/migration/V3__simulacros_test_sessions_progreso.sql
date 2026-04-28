-- V3: Simulacros, sesiones de test y progreso del usuario

CREATE TABLE simulacros (
    id               BIGSERIAL   PRIMARY KEY,
    rama_id          BIGINT      NOT NULL REFERENCES ramas_oposiciones(id),
    nombre           VARCHAR(255) NOT NULL,
    duracion_minutos INTEGER     NOT NULL,
    preguntas_count  INTEGER     NOT NULL,
    temas_incluidos  JSONB       NOT NULL,
    fecha_oficial    DATE,
    created_at       TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE test_sessions (
    id               BIGSERIAL   PRIMARY KEY,
    usuario_id       BIGINT      NOT NULL REFERENCES usuarios(id),
    simulacro_id     BIGINT      REFERENCES simulacros(id),
    rama_id          BIGINT      NOT NULL REFERENCES ramas_oposiciones(id),
    tipo             VARCHAR(50) NOT NULL,
    estado           VARCHAR(50) NOT NULL DEFAULT 'EN_CURSO',
    pregunta_ids     JSONB       NOT NULL,
    nota             DOUBLE PRECISION,
    total_preguntas  INTEGER     NOT NULL,
    correctas        INTEGER,
    fecha_inicio     TIMESTAMP   NOT NULL,
    fecha_fin        TIMESTAMP,
    created_at       TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE progreso_usuario (
    id                BIGSERIAL   PRIMARY KEY,
    usuario_id        BIGINT      NOT NULL REFERENCES usuarios(id),
    pregunta_id       BIGINT      NOT NULL REFERENCES preguntas(id),
    test_session_id   BIGINT      REFERENCES test_sessions(id),
    respuesta_usuario VARCHAR(500),
    correcto          BOOLEAN     NOT NULL,
    fecha_respuesta   TIMESTAMP   NOT NULL,
    created_at        TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_simulacros_rama_id        ON simulacros      (rama_id);
CREATE INDEX idx_test_sessions_usuario_id  ON test_sessions   (usuario_id);
CREATE INDEX idx_test_sessions_estado      ON test_sessions   (usuario_id, estado);
CREATE INDEX idx_test_sessions_fecha_fin   ON test_sessions   (usuario_id, fecha_fin DESC);
CREATE INDEX idx_progreso_usuario_id       ON progreso_usuario (usuario_id);
CREATE INDEX idx_progreso_pregunta_id      ON progreso_usuario (pregunta_id);
CREATE INDEX idx_progreso_correcto         ON progreso_usuario (usuario_id, correcto);
