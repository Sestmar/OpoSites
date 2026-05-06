-- V17 — Titulo y url_externa a TEXT (algunos ítems del BOE superan VARCHAR(500))
ALTER TABLE noticias_convocatorias
    ALTER COLUMN titulo TYPE TEXT;

ALTER TABLE noticias_convocatorias
    ALTER COLUMN url_externa TYPE TEXT;
