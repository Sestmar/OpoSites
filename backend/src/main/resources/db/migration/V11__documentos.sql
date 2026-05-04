-- V11: Módulo de documentos personales + materiales generados por IA

CREATE TABLE documentos (
    id             BIGSERIAL    PRIMARY KEY,
    usuario_id     BIGINT       NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    nombre         VARCHAR(255) NOT NULL,
    tipo_archivo   VARCHAR(10)  NOT NULL,          -- 'PDF' | 'TXT'
    ruta_fisica    VARCHAR(500) NOT NULL,
    texto_extraido TEXT,                           -- null si la extracción falló
    tamano_bytes   BIGINT       NOT NULL,
    creado_en      TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE materiales_generados (
    id           BIGSERIAL   PRIMARY KEY,
    documento_id BIGINT      NOT NULL REFERENCES documentos(id) ON DELETE CASCADE,
    tipo         VARCHAR(50) NOT NULL,             -- 'FLASHCARDS' | 'RESUMEN' | 'CONCEPTOS_CLAVE'
    contenido    TEXT        NOT NULL,             -- JSON string generado por IA
    creado_en    TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_documentos_usuario_id       ON documentos          (usuario_id);
CREATE INDEX idx_materiales_documento_id     ON materiales_generados (documento_id);
