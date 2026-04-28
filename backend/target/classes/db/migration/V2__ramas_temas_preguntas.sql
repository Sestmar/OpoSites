-- V2: Tablas de contenido (ramas, temas, preguntas)
-- y FK pendiente de V1 en usuarios.rama_principal_id

CREATE TABLE ramas_oposiciones (
    id                  BIGSERIAL    PRIMARY KEY,
    nombre              VARCHAR(255) NOT NULL,
    temario_oficial_url VARCHAR(500),
    temas_count         INTEGER      NOT NULL DEFAULT 0,
    active              BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE temas (
    id               BIGSERIAL    PRIMARY KEY,
    rama_id          BIGINT       NOT NULL REFERENCES ramas_oposiciones(id),
    nombre           VARCHAR(255) NOT NULL,
    orden            INTEGER      NOT NULL DEFAULT 0,
    descripcion_corta VARCHAR(500),
    preguntas_count  INTEGER      NOT NULL DEFAULT 0,
    created_at       TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE preguntas (
    id               BIGSERIAL   PRIMARY KEY,
    tema_id          BIGINT      NOT NULL REFERENCES temas(id),
    enunciado        TEXT        NOT NULL,
    tipo             VARCHAR(50) NOT NULL,
    opciones         JSONB,
    respuesta_correcta VARCHAR(500) NOT NULL,
    explicacion      TEXT,
    dificultad       INTEGER     NOT NULL CHECK (dificultad BETWEEN 1 AND 5),
    created_at       TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_temas_rama_id        ON temas     (rama_id);
CREATE INDEX idx_preguntas_tema_id    ON preguntas (tema_id);
CREATE INDEX idx_preguntas_tipo       ON preguntas (tipo);
CREATE INDEX idx_preguntas_dificultad ON preguntas (dificultad);

-- FK que quedó sin constraint en V1 (ramas no existía todavía)
ALTER TABLE usuarios
    ADD CONSTRAINT fk_usuarios_rama
    FOREIGN KEY (rama_principal_id) REFERENCES ramas_oposiciones(id)
    ON DELETE SET NULL;
