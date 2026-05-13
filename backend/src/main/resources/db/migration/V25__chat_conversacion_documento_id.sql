-- 1.4 — Documento como contexto del chat
-- FK nullable: permite anclar una conversación a un documento del usuario.
-- ON DELETE SET NULL: si el documento se borra, la conversación sigue funcionando sin contexto documental.
ALTER TABLE chat_conversaciones
    ADD COLUMN documento_id BIGINT REFERENCES documentos(id) ON DELETE SET NULL;
