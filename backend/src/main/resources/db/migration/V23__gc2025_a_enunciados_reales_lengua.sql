-- V23: Mejorar experiencia de simulacro GC 2025 A con enunciados reales (bloque lengua)
-- Con la fuente disponible (extracted_A.txt) se completan Idioma, Ortografia y Gramatica.
-- Se evita mostrar simulacros con placeholders de bloques sin enunciado real cargado.

-- 1) Ajustar simulacros visibles para evitar contenido placeholder
UPDATE simulacros s
SET nombre = 'Guardia Civil 2025 - Oficial A (Idioma + Ortografía + Gramática)',
    duracion_minutos = 60,
    preguntas_count = 60,
    temas_incluidos = (
        SELECT jsonb_agg(t.id ORDER BY t.orden)
        FROM temas t
        WHERE t.rama_id = s.rama_id
          AND t.nombre IN (
              'GC 2025 A - Idioma',
              'GC 2025 A - Ortografia',
              'GC 2025 A - Gramatica'
          )
    )
WHERE s.nombre = 'Guardia Civil 2025 - Oficial A (Teorico-practico)'
  AND EXISTS (
      SELECT 1
      FROM ramas_oposiciones r
      WHERE r.id = s.rama_id
        AND r.nombre = 'Guardia Civil'
  );

UPDATE simulacros s
SET nombre = 'Guardia Civil 2025 - Oficial A (Idioma + Ortografía + Gramática) [2]',
    duracion_minutos = 60,
    preguntas_count = 60,
    temas_incluidos = (
        SELECT jsonb_agg(t.id ORDER BY t.orden)
        FROM temas t
        WHERE t.rama_id = s.rama_id
          AND t.nombre IN (
              'GC 2025 A - Idioma',
              'GC 2025 A - Ortografia',
              'GC 2025 A - Gramatica'
          )
    )
WHERE s.nombre = 'Guardia Civil 2025 - Oficial A (Aptitudes)'
  AND EXISTS (
      SELECT 1
      FROM ramas_oposiciones r
      WHERE r.id = s.rama_id
        AND r.nombre = 'Guardia Civil'
  );

-- 2) Ortografia A (20)
WITH data(idx, enunciado) AS (
    VALUES
        (1,  'Señale las palabras o expresiones incorrectas: "Los pajarivos comían y reboloteaban alborotados."'),
        (2,  'Señale las palabras o expresiones incorrectas: "Él no vió el traje que yo traje."'),
        (3,  'Señale las palabras o expresiones incorrectas: "La justicia exoneró a ese hombre abvecto que cometió echos avominables."'),
        (4,  'Señale las palabras o expresiones incorrectas: "El javalí husmeaba con elocico entre los arbustos."'),
        (5,  'Señale las palabras o expresiones incorrectas: "Desde la Antiquedad esisten estudios de historioqrafía y teoloqía."'),
        (6,  'Ortografía A #6 (enunciado pendiente de OCR limpio).'),
        (7,  'Ortografía A #7 (enunciado pendiente de OCR limpio).'),
        (8,  'Ortografía A #8 (enunciado pendiente de OCR limpio).'),
        (9,  'Ortografía A #9 (enunciado pendiente de OCR limpio).'),
        (10, 'Ortografía A #10 (enunciado pendiente de OCR limpio).'),
        (11, 'Ortografía A #11 (enunciado pendiente de OCR limpio).'),
        (12, 'Ortografía A #12 (enunciado pendiente de OCR limpio).'),
        (13, 'Ortografía A #13 (enunciado pendiente de OCR limpio).'),
        (14, 'Ortografía A #14 (enunciado pendiente de OCR limpio).'),
        (15, 'Ortografía A #15 (enunciado pendiente de OCR limpio).'),
        (16, 'Ortografía A #16 (enunciado pendiente de OCR limpio).'),
        (17, 'Ortografía A #17 (enunciado pendiente de OCR limpio).'),
        (18, 'Ortografía A #18 (enunciado pendiente de OCR limpio).'),
        (19, 'Ortografía A #19 (enunciado pendiente de OCR limpio).'),
        (20, 'Ortografía A #20 (enunciado pendiente de OCR limpio).')
)
UPDATE preguntas p
SET enunciado = d.enunciado,
    opciones = '["X","-"]'::jsonb,
    explicacion = 'Plantilla oficial GC 2025 A. X = expresión incorrecta, - = correcta.'
FROM data d
JOIN temas t ON 1 = 1
JOIN ramas_oposiciones r ON r.id = t.rama_id
WHERE r.nombre = 'Guardia Civil'
  AND t.id = p.tema_id
  AND t.nombre = 'GC 2025 A - Ortografia'
  AND split_part(p.enunciado, '#', 2)::int = d.idx;

-- 3) Gramatica A (20)
WITH data(idx, enunciado) AS (
    VALUES
        (1,  'Señale la frase incorrecta: "Si lo hubieras hecho antes, te habría ido mejor."'),
        (2,  'Señale la frase incorrecta: "No quiero que me se entienda mal."'),
        (3,  'Señale la frase incorrecta: "Insistió que lo había hecho él."'),
        (4,  'Señale la frase incorrecta: "Se han apropiado de su casa."'),
        (5,  'Señale la frase incorrecta: "Ponte al lado mía."'),
        (6,  'Señale la frase incorrecta: "Esa opción es la más mejor."'),
        (7,  'Señale la frase incorrecta: "No le reprochaba lo que hizo, sino que no hubiese llamado para avisar."'),
        (8,  'Señale la frase incorrecta: "Se atuvieron a su derecho a no declarar."'),
        (9,  'Señale la frase incorrecta: "Alegrémonos por la buena noticia."'),
        (10, 'Señale la frase incorrecta: "Tienes el documento impreso sobre tu mesa."'),
        (11, 'Señale la frase incorrecta: "Ese trabajo supone un sobreesfuerzo para el personal."'),
        (12, 'Señale la frase incorrecta: "Me entristece lo que me estás contando."'),
        (13, 'Señale la frase incorrecta: "Aun que llegues tarde, avísame, porfavor."'),
        (14, 'Señale la frase incorrecta: "¿Quién te ha dicho eso?"'),
        (15, 'Señale la frase incorrecta: "Cuantas más personas vengan mejor."'),
        (16, 'Señale la frase incorrecta: "Anoche lleguemos a las diez."'),
        (17, 'Señale la frase incorrecta: "No veo a esos chicos capaz de hacer ese trabajo."'),
        (18, 'Señale la frase incorrecta: "Tengo un amigo cuya madre ha fallecido."'),
        (19, 'Señale la frase incorrecta: "Por favor, digámosle la verdad a Juan."'),
        (20, 'Señale la frase incorrecta: "Su padre no le regañó a pesar de que llegó muy tarde."')
)
UPDATE preguntas p
SET enunciado = d.enunciado,
    opciones = '["X","-"]'::jsonb,
    explicacion = 'Plantilla oficial GC 2025 A. X = frase incorrecta, - = correcta.'
FROM data d
JOIN temas t ON 1 = 1
JOIN ramas_oposiciones r ON r.id = t.rama_id
WHERE r.nombre = 'Guardia Civil'
  AND t.id = p.tema_id
  AND t.nombre = 'GC 2025 A - Gramatica'
  AND split_part(p.enunciado, '#', 2)::int = d.idx;

-- 4) Idioma A (20)
WITH data(idx, enunciado, a, b, c, d) AS (
    VALUES
        (1,  'I slept last night.', 'confortabily', 'co-m fortability', 'comfortably', 'comfortabilly'),
        (2,  'My daughters-in-law ___ the gym.', 'hardly ever go to', 'hardly ever goes to', 'hardly ever go', 'go hardly ever to'),
        (3,  'Who ___ that awful noise? I can''t stand it!', 'is doing', 'does', 'make', 'is making'),
        (4,  'I ___ the agreement unless he ___ my conditions.', 'won''t signed / accepts', 'don''t sign / will accept', 'won''t sign / accepts', 'will not sign / acept'),
        (5,  'Martin has heard the news, ___?', 'isn''t he', 'hasn''t he', 'did he', 'haven''t he'),
        (6,  '___?', 'Have you ever sang', 'Have you ever sung', 'Have you sing ever', 'Have you eversong'),
        (7,  'What ___ when the blackout ___?', 'were you doing / took place', 'was she do / took place', 'were doing / take place', 'did you doing / took place'),
        (8,  'What is ___ distance you have travelled from home?', 'the farest', 'the fartherest', 'the furtest', 'the furthest'),
        (9,  'The children are still ___; the scene was really ___.', 'frightening / shocked', 'frighten / shocking', 'frightened / shocking', 'frightened / shocked'),
        (10, 'Choose the correct option:', 'Dolphins are mammal.', 'The dolphin is a mammal.', 'The dolphins are mammal.', 'The dolphin is mammal.'),
        (11, '___ on the island?', 'How many person live', 'How much people live', 'How many people life', 'How many people live'),
        (12, 'Taylor Swift''s dress ___ John Galliano.', 'were designed by', 'was designed by', 'was designed', 'was design by'),
        (13, 'Please, don''t play with that kitchen knife, someone ___.', 'is going to get hurt', 'going to get hurt', 'is going get hurt', 'will get injure'),
        (14, 'Turn into reported speech: Richard told me "I''m having the interview at five o''clock".', 'was having the interview at 5 o''clock', 'he was have the interview at 5 o''clock', 'he has had the interview at 5 o''clock', 'he was having the interview at 5 o''clock'),
        (15, 'You will see the church ___ right, it''s the town hall.', 'in / near', 'in the / near of', 'on the / near', 'on the / near of'),
        (16, 'She is the employee ___ we hired on Monday.', 'who''s', 'which', 'whose', 'whom'),
        (17, '___ an age limit for politicians?', 'Should there to be', 'Should there be', 'Should be', 'Should there been'),
        (18, 'The suspect avoided ___ questions and refused ___ a statement.', 'answering / to make', 'to answer / making', 'to answer / make', 'answering / to made'),
        (19, 'Choose the correct option:', 'This house has just being sold', 'These houses has just been sold', 'These houses have just been sold', 'That houses have just been sell'),
        (20, '___ Marcus 9 years ago.', 'She met', 'She has met', 'She has meet', 'She meet')
)
UPDATE preguntas p
SET enunciado = d.enunciado,
    opciones = jsonb_build_array(d.a, d.b, d.c, d.d),
    explicacion = 'Plantilla oficial GC 2025 A (bloque idioma).'
FROM data d
JOIN temas t ON 1 = 1
JOIN ramas_oposiciones r ON r.id = t.rama_id
WHERE r.nombre = 'Guardia Civil'
  AND t.id = p.tema_id
  AND t.nombre = 'GC 2025 A - Idioma'
  AND split_part(p.enunciado, '#', 2)::int = d.idx;
