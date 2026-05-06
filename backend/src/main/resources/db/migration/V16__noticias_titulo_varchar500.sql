-- V16 — Ampliar titulo de noticias a VARCHAR(500) (títulos del BOE superan 255 chars)
ALTER TABLE noticias_convocatorias
    ALTER COLUMN titulo TYPE VARCHAR(500);
