-- V24: Corregir y completar enunciados de Ortografía GC 2025 A
--
-- El examen real tiene 5 oraciones con 4 casillas numeradas c/u (= 20 casillas).
-- V23 asignó erróneamente el enunciado de la oración N a la casilla N (en vez de
-- repartir las 4 casillas de cada oración). Esta migración lo corrige todo.
--
-- Distribución correcta (confirmada con extracted_A.txt + Plantilla oficial):
--   Casillas  1– 4 → Oración 1: "Los pajarivos comían y reboloteaban alborotados."
--   Casillas  5– 8 → Oración 2: "Él no vió el traje que yo traje."
--   Casillas  9–12 → Oración 3: "La justicia exoneró a ese hombre abvecto que cometió echos avominables."
--   Casillas 13–16 → Oración 4: "El javalí husmeaba con elocico entre los arbustos."
--   Casillas 17–20 → Oración 5: "Desde la Antiquedad esisten estudios de historioqrafía y teoloqía."

WITH ortografia_ordenada AS (
    SELECT p.id,
           ROW_NUMBER() OVER (ORDER BY p.id) AS pos
    FROM preguntas p
    JOIN temas t ON t.id = p.tema_id
    JOIN ramas_oposiciones r ON r.id = t.rama_id
    WHERE r.nombre = 'Guardia Civil'
      AND t.nombre = 'GC 2025 A - Ortografia'
),
enunciados AS (
    SELECT pos,
           id,
           CASE
               WHEN pos BETWEEN 1  AND 4  THEN 'Señale las palabras o expresiones incorrectas: "Los pajarivos comían y reboloteaban alborotados."'
               WHEN pos BETWEEN 5  AND 8  THEN 'Señale las palabras o expresiones incorrectas: "Él no vió el traje que yo traje."'
               WHEN pos BETWEEN 9  AND 12 THEN 'Señale las palabras o expresiones incorrectas: "La justicia exoneró a ese hombre abvecto que cometió echos avominables."'
               WHEN pos BETWEEN 13 AND 16 THEN 'Señale las palabras o expresiones incorrectas: "El javalí husmeaba con elocico entre los arbustos."'
               WHEN pos BETWEEN 17 AND 20 THEN 'Señale las palabras o expresiones incorrectas: "Desde la Antiquedad esisten estudios de historioqrafía y teoloqía."'
           END AS enunciado_correcto
    FROM ortografia_ordenada
)
UPDATE preguntas p
SET enunciado    = e.enunciado_correcto,
    opciones     = '["X","-"]'::jsonb,
    explicacion  = 'Plantilla oficial GC 2025 A. X = expresión incorrecta, - = correcta.'
FROM enunciados e
WHERE p.id = e.id;
