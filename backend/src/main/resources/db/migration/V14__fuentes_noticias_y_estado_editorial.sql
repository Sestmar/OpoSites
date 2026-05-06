-- ──────────────────────────────────────────────────────────────────────────────
-- V14 — Fuentes de noticias + estado editorial
-- ──────────────────────────────────────────────────────────────────────────────

CREATE TABLE fuentes_noticias (
    id           BIGSERIAL PRIMARY KEY,
    nombre       VARCHAR(255) NOT NULL,
    url          VARCHAR(500) NOT NULL,
    tipo_fuente  VARCHAR(30)  NOT NULL CHECK (tipo_fuente IN ('RSS', 'API', 'SCRAPING', 'DUMMY')),
    rama_id      BIGINT REFERENCES ramas_oposiciones(id) ON DELETE SET NULL,
    activa       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP    NOT NULL DEFAULT NOW()
);

ALTER TABLE noticias_convocatorias
    ADD COLUMN estado_editorial VARCHAR(20) NOT NULL DEFAULT 'PUBLICADA'
        CHECK (estado_editorial IN ('BORRADOR', 'PUBLICADA', 'RECHAZADA'));

CREATE INDEX idx_fuentes_noticias_activa ON fuentes_noticias(activa);
CREATE INDEX idx_noticias_url_fecha ON noticias_convocatorias (lower(url_externa), fecha_publicacion)
    WHERE url_externa IS NOT NULL;
CREATE INDEX idx_noticias_titulo_fecha ON noticias_convocatorias (lower(titulo), fecha_publicacion);

-- Semillas dummy para validar el pipeline semiautomático sin scraping complejo.
INSERT INTO fuentes_noticias (nombre, url, tipo_fuente, rama_id, activa)
SELECT
    'Fuente dummy general',
    'https://dummy.oposites.local/general',
    'DUMMY',
    NULL,
    TRUE
WHERE NOT EXISTS (
    SELECT 1
    FROM fuentes_noticias
    WHERE nombre = 'Fuente dummy general'
);

INSERT INTO fuentes_noticias (nombre, url, tipo_fuente, rama_id, activa)
SELECT
    'Fuente dummy Policía Nacional',
    'https://dummy.oposites.local/policia',
    'DUMMY',
    (SELECT id FROM ramas_oposiciones WHERE nombre = 'Policía Nacional' LIMIT 1),
    TRUE
WHERE NOT EXISTS (
    SELECT 1
    FROM fuentes_noticias
    WHERE nombre = 'Fuente dummy Policía Nacional'
);
