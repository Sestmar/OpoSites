-- Tests generados desde documento (flujo independiente de materiales_generados)

CREATE TABLE documento_tests (
    id          BIGSERIAL PRIMARY KEY,
    documento_id BIGINT NOT NULL REFERENCES documentos(id) ON DELETE CASCADE,
    creado_en   TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE documento_test_preguntas (
    id                  BIGSERIAL PRIMARY KEY,
    test_id             BIGINT NOT NULL REFERENCES documento_tests(id) ON DELETE CASCADE,
    enunciado           TEXT NOT NULL,
    opciones            TEXT NOT NULL,   -- JSON array de 4 strings
    respuesta_correcta  INT  NOT NULL,   -- índice 0-3
    explicacion         TEXT NOT NULL,
    orden               INT  NOT NULL
);

CREATE INDEX idx_documento_tests_documento_id     ON documento_tests(documento_id);
CREATE INDEX idx_doc_test_preguntas_test_id       ON documento_test_preguntas(test_id);
