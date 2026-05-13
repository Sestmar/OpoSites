-- 5.2 — Repaso personalizado por fallos
CREATE TABLE sesiones_repaso (
    id              BIGSERIAL PRIMARY KEY,
    usuario_id      BIGINT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    rama_id         BIGINT REFERENCES ramas_oposiciones(id),
    -- [{id, nombre, porcentajeAcierto}] — temas seleccionados para la sesión
    temas           JSONB NOT NULL DEFAULT '[]',
    -- [{enunciado, opciones[], respuestaCorrecta (0-3), explicacion, temaId, temaNombre}]
    preguntas       JSONB NOT NULL DEFAULT '[]',
    estado          VARCHAR(20) NOT NULL DEFAULT 'EN_CURSO',
    total_preguntas SMALLINT NOT NULL DEFAULT 0,
    correctas       SMALLINT,
    puntuacion      NUMERIC(4,1),
    created_at      TIMESTAMP NOT NULL DEFAULT now(),
    completado_at   TIMESTAMP
);

CREATE TABLE respuestas_sesion_repaso (
    id                  BIGSERIAL PRIMARY KEY,
    sesion_repaso_id    BIGINT NOT NULL REFERENCES sesiones_repaso(id) ON DELETE CASCADE,
    pregunta_index      SMALLINT NOT NULL,
    tema_id             BIGINT REFERENCES temas(id),
    respuesta_usuario   SMALLINT NOT NULL,   -- 0-3 (índice opción)
    es_correcta         BOOLEAN NOT NULL,
    created_at          TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE (sesion_repaso_id, pregunta_index)
);
