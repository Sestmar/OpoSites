-- 5.2 — Repaso personalizado
-- 1. pregunta_id ahora es nullable para soportar respuestas de sesiones de repaso IA
ALTER TABLE progreso_usuario ALTER COLUMN pregunta_id DROP NOT NULL;

-- 2. tema_id directo para registrar el tema cuando no hay pregunta (repaso IA)
ALTER TABLE progreso_usuario ADD COLUMN tema_id BIGINT REFERENCES temas(id);
