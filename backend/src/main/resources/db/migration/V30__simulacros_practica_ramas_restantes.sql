-- V30: Simulacros de práctica para ramas sin simulacro oficial
-- Crea 1 simulacro de práctica por rama usando los 5 temas y 50 preguntas ya cargadas.
-- Sin fecha_oficial porque no son exámenes reales.

INSERT INTO simulacros (rama_id, nombre, duracion_minutos, preguntas_count, temas_incluidos)
SELECT r.id,
       'Simulacro de Práctica - Policía Nacional',
       60,
       50,
       (SELECT jsonb_agg(t.id ORDER BY t.orden) FROM temas t WHERE t.rama_id = r.id)
FROM ramas_oposiciones r
WHERE r.nombre = 'Policía Nacional';

INSERT INTO simulacros (rama_id, nombre, duracion_minutos, preguntas_count, temas_incluidos)
SELECT r.id,
       'Simulacro de Práctica - Ayudantes II.PP.',
       60,
       50,
       (SELECT jsonb_agg(t.id ORDER BY t.orden) FROM temas t WHERE t.rama_id = r.id)
FROM ramas_oposiciones r
WHERE r.nombre = 'Cuerpo de Ayudantes de II.PP. (Prisiones)';

INSERT INTO simulacros (rama_id, nombre, duracion_minutos, preguntas_count, temas_incluidos)
SELECT r.id,
       'Simulacro de Práctica - Fuerzas Armadas',
       60,
       50,
       (SELECT jsonb_agg(t.id ORDER BY t.orden) FROM temas t WHERE t.rama_id = r.id)
FROM ramas_oposiciones r
WHERE r.nombre = 'Fuerzas Armadas';

INSERT INTO simulacros (rama_id, nombre, duracion_minutos, preguntas_count, temas_incluidos)
SELECT r.id,
       'Simulacro de Práctica - TCAE',
       60,
       50,
       (SELECT jsonb_agg(t.id ORDER BY t.orden) FROM temas t WHERE t.rama_id = r.id)
FROM ramas_oposiciones r
WHERE r.nombre = 'TCAE del Servicio de Salud (Estatutario)';
