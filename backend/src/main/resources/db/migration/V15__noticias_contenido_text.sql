-- V15 — Ampliar contenido de noticias a TEXT (los RSS del BOE superan VARCHAR(255))
ALTER TABLE noticias_convocatorias
    ALTER COLUMN contenido TYPE TEXT;
