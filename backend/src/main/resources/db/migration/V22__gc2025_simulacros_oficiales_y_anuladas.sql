-- V22: Soporte de preguntas anuladas + seed simulacro oficial GC 2025 (Modelo A)
-- Nota: Modelo B queda pendiente de carga de enunciados.

ALTER TABLE preguntas
    ADD COLUMN anulada BOOLEAN NOT NULL DEFAULT FALSE;

-- Temas oficiales para simulacros GC 2025 Modelo A
INSERT INTO temas (rama_id, nombre, orden, descripcion_corta, preguntas_count)
SELECT r.id, v.nombre, v.orden, v.descripcion, v.preguntas_count
FROM ramas_oposiciones r
JOIN (
    VALUES
        ('GC 2025 A - Conocimientos', 1001, 'Plantilla oficial GC 2025 (modelo A): bloque de conocimientos', 100),
        ('GC 2025 A - Idioma', 1002, 'Plantilla oficial GC 2025 (modelo A): bloque de idioma', 20),
        ('GC 2025 A - Ortografia', 1003, 'Plantilla oficial GC 2025 (modelo A): bloque de ortografia', 20),
        ('GC 2025 A - Gramatica', 1004, 'Plantilla oficial GC 2025 (modelo A): bloque de gramatica', 20),
        ('GC 2025 A - Aptitudes', 1005, 'Plantilla oficial GC 2025 (modelo A): bloque de aptitudes', 80)
) AS v(nombre, orden, descripcion, preguntas_count) ON 1 = 1
WHERE r.nombre = 'Guardia Civil';

-- Conocimientos A (1-100)
WITH respuestas(respuesta, idx) AS (
    SELECT *
    FROM unnest(ARRAY[
        'C','B','A','A','C','C','D','B','C','C',
        'A','B','A','C','D','B','D','B','A','A',
        'B','D','B','D','D','B','D','B','C','D',
        'D','A','B','A','C','B','D','C','D','A',
        'B','B','A','A','D','C','C','B','A','B',
        'B','B','D','C','A','C','A','D','B','B',
        'C','A','B','B','A','B','D','C','D','A',
        'A','C','C','B','D','A','A','A','C','C',
        'D','C','A','A','A','C','C','C','A','B',
        'C','C','A','B','D','C','C','D','A','D'
    ]) WITH ORDINALITY AS t(respuesta, idx)
)
INSERT INTO preguntas (tema_id, enunciado, tipo, opciones, respuesta_correcta, explicacion, dificultad, anulada)
SELECT t.id,
       'GC2025-A CONOCIMIENTOS #' || r.idx,
       'MCQ',
       '["A","B","C","D"]'::jsonb,
       r.respuesta,
       'Clave oficial plantilla de resultados GC 2025 (Modelo A).',
       3,
       FALSE
FROM respuestas r
JOIN temas t ON t.nombre = 'GC 2025 A - Conocimientos'
JOIN ramas_oposiciones ro ON ro.id = t.rama_id
WHERE ro.nombre = 'Guardia Civil';

-- Idioma A (1-20)
WITH respuestas(respuesta, idx) AS (
    SELECT *
    FROM unnest(ARRAY[
        'C','A','D','C','B','B','A','D','C','B',
        'D','B','A','D','C','D','B','A','C','A'
    ]) WITH ORDINALITY AS t(respuesta, idx)
)
INSERT INTO preguntas (tema_id, enunciado, tipo, opciones, respuesta_correcta, explicacion, dificultad, anulada)
SELECT t.id,
       'GC2025-A IDIOMA #' || r.idx,
       'MCQ',
       '["A","B","C","D"]'::jsonb,
       r.respuesta,
       'Clave oficial plantilla de resultados GC 2025 (Modelo A).',
       2,
       FALSE
FROM respuestas r
JOIN temas t ON t.nombre = 'GC 2025 A - Idioma'
JOIN ramas_oposiciones ro ON ro.id = t.rama_id
WHERE ro.nombre = 'Guardia Civil';

-- Ortografia A (1-20): X = incorrecta, - = correcta
WITH respuestas(respuesta, idx) AS (
    SELECT *
    FROM unnest(ARRAY[
        'X','-','X','-','-','X','-','-','-','-',
        'X','X','-','-','X','-','X','X','-','-'
    ]) WITH ORDINALITY AS t(respuesta, idx)
)
INSERT INTO preguntas (tema_id, enunciado, tipo, opciones, respuesta_correcta, explicacion, dificultad, anulada)
SELECT t.id,
       'GC2025-A ORTOGRAFIA #' || r.idx,
       'TRUE_FALSE',
       '["X","-"]'::jsonb,
       r.respuesta,
       'Clave oficial plantilla de resultados GC 2025 (Modelo A). X=incorrecta, -=correcta.',
       2,
       FALSE
FROM respuestas r
JOIN temas t ON t.nombre = 'GC 2025 A - Ortografia'
JOIN ramas_oposiciones ro ON ro.id = t.rama_id
WHERE ro.nombre = 'Guardia Civil';

-- Gramatica A (1-20): X = incorrecta, - = correcta
WITH respuestas(respuesta, idx) AS (
    SELECT *
    FROM unnest(ARRAY[
        '-','X','X','-','X','X','-','-','-','-',
        '-','X','X','-','-','X','X','-','-','-'
    ]) WITH ORDINALITY AS t(respuesta, idx)
)
INSERT INTO preguntas (tema_id, enunciado, tipo, opciones, respuesta_correcta, explicacion, dificultad, anulada)
SELECT t.id,
       'GC2025-A GRAMATICA #' || r.idx,
       'TRUE_FALSE',
       '["X","-"]'::jsonb,
       r.respuesta,
       'Clave oficial plantilla de resultados GC 2025 (Modelo A). X=incorrecta, -=correcta.',
       2,
       FALSE
FROM respuestas r
JOIN temas t ON t.nombre = 'GC 2025 A - Gramatica'
JOIN ramas_oposiciones ro ON ro.id = t.rama_id
WHERE ro.nombre = 'Guardia Civil';

-- Aptitudes A (1-80). Item 48 anulado.
WITH respuestas(respuesta, idx) AS (
    SELECT *
    FROM unnest(ARRAY[
        'B','A','A','D','D','C','D','B','B','A',
        'D','C','C','A','C','D','D','C','A','C',
        'D','C','D','A','D','B','A','B','A','C',
        'C','B','D','C','D','A','C','A','B','B',
        'C','B','C','B','C','C','A','ANULADA','D','C',
        'B','C','B','A','B','A','D','C','D','A',
        'A','A','B','D','A','D','B','D','D','B',
        'A','C','C','B','D','C','A','B','B','B'
    ]) WITH ORDINALITY AS t(respuesta, idx)
)
INSERT INTO preguntas (tema_id, enunciado, tipo, opciones, respuesta_correcta, explicacion, dificultad, anulada)
SELECT t.id,
       'GC2025-A APTITUDES #' || r.idx,
       'MCQ',
       '["A","B","C","D"]'::jsonb,
       r.respuesta,
       CASE
           WHEN r.respuesta = 'ANULADA'
               THEN 'Item anulado en plantilla oficial GC 2025 (Modelo A).'
           ELSE 'Clave oficial plantilla de resultados GC 2025 (Modelo A).'
       END,
       3,
       (r.respuesta = 'ANULADA')
FROM respuestas r
JOIN temas t ON t.nombre = 'GC 2025 A - Aptitudes'
JOIN ramas_oposiciones ro ON ro.id = t.rama_id
WHERE ro.nombre = 'Guardia Civil';

-- Simulacros oficiales modelo A
INSERT INTO simulacros (rama_id, nombre, duracion_minutos, preguntas_count, temas_incluidos, fecha_oficial)
SELECT r.id,
       'Guardia Civil 2025 - Oficial A (Teorico-practico)',
       140,
       160,
       (
           SELECT jsonb_agg(t.id ORDER BY t.orden)
           FROM temas t
           WHERE t.rama_id = r.id
             AND t.nombre IN (
                 'GC 2025 A - Conocimientos',
                 'GC 2025 A - Idioma',
                 'GC 2025 A - Ortografia',
                 'GC 2025 A - Gramatica'
             )
       ),
       DATE '2025-09-06'
FROM ramas_oposiciones r
WHERE r.nombre = 'Guardia Civil';

INSERT INTO simulacros (rama_id, nombre, duracion_minutos, preguntas_count, temas_incluidos, fecha_oficial)
SELECT r.id,
       'Guardia Civil 2025 - Oficial A (Aptitudes)',
       60,
       80,
       (
           SELECT jsonb_agg(t.id ORDER BY t.orden)
           FROM temas t
           WHERE t.rama_id = r.id
             AND t.nombre = 'GC 2025 A - Aptitudes'
       ),
       DATE '2025-09-06'
FROM ramas_oposiciones r
WHERE r.nombre = 'Guardia Civil';

-- Recalcular contador de temas de Guardia Civil
UPDATE ramas_oposiciones r
SET temas_count = (
    SELECT COUNT(*) FROM temas t WHERE t.rama_id = r.id
)
WHERE r.nombre = 'Guardia Civil';
