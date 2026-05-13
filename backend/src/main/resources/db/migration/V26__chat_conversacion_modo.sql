-- 1.6 — Modo examinador: columna modo en chat_conversaciones
-- GENERAL = asistente conversacional (default)
-- EXAMINADOR = la IA formula preguntas y evalúa respuestas
ALTER TABLE chat_conversaciones
    ADD COLUMN modo VARCHAR(20) NOT NULL DEFAULT 'GENERAL';
