-- ──────────────────────────────────────────────────────────────────────────────
-- V4 — Noticias/Convocatorias + Tabla join noticia_leida + Calendario de eventos
-- ──────────────────────────────────────────────────────────────────────────────

-- 1. Noticias y convocatorias
CREATE TABLE noticias_convocatorias (
    id                 BIGSERIAL PRIMARY KEY,
    rama_id            BIGINT REFERENCES ramas_oposiciones(id) ON DELETE SET NULL,
    titulo             VARCHAR(255) NOT NULL,
    contenido          TEXT         NOT NULL,
    url_externa        VARCHAR(500),
    tipo               VARCHAR(30)  NOT NULL CHECK (tipo IN ('CONVOCATORIA', 'CAMBIO', 'NOTICIA')),
    fecha_publicacion  TIMESTAMP    NOT NULL,
    active             BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at         TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- 2. Tabla join: noticias leídas por usuario (sustituye al JSON array del DATABASE.md)
CREATE TABLE noticia_leida (
    noticia_id  BIGINT    NOT NULL REFERENCES noticias_convocatorias(id) ON DELETE CASCADE,
    usuario_id  BIGINT    NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    leida_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (noticia_id, usuario_id)
);

-- 3. Calendario de eventos del usuario
CREATE TABLE calendario_eventos (
    id             BIGSERIAL PRIMARY KEY,
    usuario_id     BIGINT       NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    rama_id        BIGINT REFERENCES ramas_oposiciones(id) ON DELETE SET NULL,
    titulo         VARCHAR(255) NOT NULL,
    descripcion    TEXT,
    fecha_inicio   TIMESTAMP    NOT NULL,
    fecha_fin      TIMESTAMP,
    tipo           VARCHAR(30)  NOT NULL CHECK (tipo IN ('ESTUDIO', 'SIMULACRO', 'CONVOCATORIA', 'MANUAL')),
    auto_generado  BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────────────────
-- Índices
-- ──────────────────────────────────────────────────────────────────────────────

-- noticia_leida: búsquedas por usuario para marcar leídas en listados
CREATE INDEX idx_noticia_leida_noticia_id  ON noticia_leida(noticia_id);
CREATE INDEX idx_noticia_leida_usuario_id  ON noticia_leida(usuario_id);

-- calendario_eventos: consultas por usuario + rango de fechas (caso más frecuente)
CREATE INDEX idx_calendario_usuario_fecha  ON calendario_eventos(usuario_id, fecha_inicio);
