-- V8: Seed data — Ramas de oposición iniciales
-- Estos registros son el catálogo base de la app.
-- Los temas y preguntas se cargan por separado desde el panel admin.

INSERT INTO ramas_oposiciones (nombre, active) VALUES
    ('Policía Nacional',                         TRUE),
    ('Guardia Civil',                            TRUE),
    ('Cuerpo de Ayudantes de II.PP. (Prisiones)', TRUE),
    ('Fuerzas Armadas',                          TRUE),
    ('Técnico Auxiliar Sanitario',               TRUE);
