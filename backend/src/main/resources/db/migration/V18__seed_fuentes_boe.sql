-- ──────────────────────────────────────────────────────────────────────────────
-- V18 — Fuentes BOE activas para ingesta de noticias
-- ──────────────────────────────────────────────────────────────────────────────

-- Desactivar fuentes dummy (solo sirven para desarrollo local)
UPDATE fuentes_noticias SET activa = FALSE WHERE tipo_fuente = 'DUMMY';

-- Insertar fuentes BOE activas (idempotente — no duplica si ya existen)
INSERT INTO fuentes_noticias (nombre, url, tipo_fuente, rama_id, activa)
SELECT 'BOE - Convocatorias', 'https://www.boe.es/rss/boe.php?s=3', 'RSS', NULL, TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM fuentes_noticias WHERE url = 'https://www.boe.es/rss/boe.php?s=3'
);

INSERT INTO fuentes_noticias (nombre, url, tipo_fuente, rama_id, activa)
SELECT 'BOE - Oposiciones y concursos', 'https://www.boe.es/rss/boe.php?s=2B', 'RSS', NULL, TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM fuentes_noticias WHERE url = 'https://www.boe.es/rss/boe.php?s=2B'
);

INSERT INTO fuentes_noticias (nombre, url, tipo_fuente, rama_id, activa)
SELECT 'BOE - Canal Oposiciones', 'https://www.boe.es/rss/canal_per.php?l=p&c=140', 'RSS', NULL, TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM fuentes_noticias WHERE url = 'https://www.boe.es/rss/canal_per.php?l=p&c=140'
);

INSERT INTO fuentes_noticias (nombre, url, tipo_fuente, rama_id, activa)
SELECT 'BOE - Canal Concursos personal', 'https://www.boe.es/rss/canal_per.php?l=p&c=141', 'RSS', NULL, TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM fuentes_noticias WHERE url = 'https://www.boe.es/rss/canal_per.php?l=p&c=141'
);
