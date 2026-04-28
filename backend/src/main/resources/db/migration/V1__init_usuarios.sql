-- V1: Tabla de usuarios
-- rama_principal_id es nullable intencionalmente en Fase 1.
-- La FK a ramas_oposiciones se añadirá en V2 cuando exista esa tabla.

CREATE TABLE usuarios (
    id                   BIGSERIAL    PRIMARY KEY,
    email                VARCHAR(255) NOT NULL UNIQUE,
    google_id            VARCHAR(255),
    nombre               VARCHAR(255) NOT NULL,
    ciudad               VARCHAR(255),
    password_hash        VARCHAR(255),
    fecha_registro       TIMESTAMP    NOT NULL DEFAULT NOW(),
    rama_principal_id    BIGINT,
    fecha_examen_objetivo DATE,
    plan_manual          JSONB,
    enabled_chat_private BOOLEAN      NOT NULL DEFAULT FALSE,
    role                 VARCHAR(50)  NOT NULL DEFAULT 'USER',
    created_at           TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_usuarios_email     ON usuarios (email);
CREATE INDEX idx_usuarios_google_id ON usuarios (google_id) WHERE google_id IS NOT NULL;
