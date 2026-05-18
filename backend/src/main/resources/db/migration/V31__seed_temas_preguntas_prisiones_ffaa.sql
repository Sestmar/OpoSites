-- V31: Temario y preguntas específicas para Prisiones y Fuerzas Armadas
-- Reemplaza el contenido genérico cargado en V20 por temario propio de cada oposición.

-- ══════════════════════════════════════════════════════════════════════════════
-- 1) LIMPIAR CONTENIDO GENÉRICO
-- ══════════════════════════════════════════════════════════════════════════════

DELETE FROM preguntas p
USING temas t, ramas_oposiciones r
WHERE p.tema_id = t.id
  AND t.rama_id = r.id
  AND r.nombre IN ('Cuerpo de Ayudantes de II.PP. (Prisiones)', 'Fuerzas Armadas');

DELETE FROM temas t
USING ramas_oposiciones r
WHERE t.rama_id = r.id
  AND r.nombre IN ('Cuerpo de Ayudantes de II.PP. (Prisiones)', 'Fuerzas Armadas');

-- ══════════════════════════════════════════════════════════════════════════════
-- 2) TEMAS — CUERPO DE AYUDANTES DE II.PP. (PRISIONES)
-- ══════════════════════════════════════════════════════════════════════════════

INSERT INTO temas (rama_id, nombre, orden, descripcion_corta, preguntas_count)
SELECT r.id, v.nombre, v.orden, v.descripcion, 10
FROM ramas_oposiciones r
JOIN (VALUES
    ('Constitución Española y Marco Jurídico Penitenciario', 1, 'CE aplicada al ámbito penitenciario: derechos fundamentales, garantías y marco legal'),
    ('Ley Orgánica General Penitenciaria',                   2, 'LO 1/1979: principios, derechos del interno, régimen y tratamiento'),
    ('Reglamento Penitenciario y Régimen de Vida',           3, 'RD 190/1996: clasificación, régimen cerrado, ordinario y abierto'),
    ('Tratamiento Penitenciario e Intervención',             4, 'Programas de tratamiento, educación, trabajo y reinserción social'),
    ('Seguridad, Disciplina y Organización del Centro',      5, 'Organización interna, régimen disciplinario y seguridad penitenciaria')
) AS v(nombre, orden, descripcion) ON 1=1
WHERE r.nombre = 'Cuerpo de Ayudantes de II.PP. (Prisiones)';

UPDATE ramas_oposiciones SET temas_count = 5
WHERE nombre = 'Cuerpo de Ayudantes de II.PP. (Prisiones)';

-- ── Preguntas — Prisiones ─────────────────────────────────────────────────────

WITH preguntas_prisiones (tema_nombre, enunciado, opciones, respuesta_correcta, explicacion, dificultad) AS (
    VALUES

    -- Tema 1: Constitución Española y Marco Jurídico Penitenciario
    ('Constitución Española y Marco Jurídico Penitenciario',
     '¿En qué artículo de la Constitución se prohíben expresamente las penas o tratos inhumanos o degradantes?',
     '["Artículo 14","Artículo 15","Artículo 17","Artículo 25"]',
     'Artículo 15',
     'El artículo 15 CE garantiza el derecho a la vida y a la integridad física y moral, y prohíbe la tortura y los tratos inhumanos o degradantes.',
     1),

    ('Constitución Española y Marco Jurídico Penitenciario',
     'Según el artículo 25.2 de la Constitución, las penas privativas de libertad estarán orientadas hacia:',
     '["La punición ejemplarizante","La reeducación y reinserción social","La separación permanente de la sociedad","La reparación económica a las víctimas"]',
     'La reeducación y reinserción social',
     'El artículo 25.2 CE establece que las penas y medidas de seguridad estarán orientadas hacia la reeducación y reinserción social.',
     1),

    ('Constitución Española y Marco Jurídico Penitenciario',
     '¿Qué artículo de la Constitución reconoce el derecho a la libertad y a la seguridad personal?',
     '["Artículo 14","Artículo 15","Artículo 17","Artículo 18"]',
     'Artículo 17',
     'El artículo 17 CE reconoce el derecho de toda persona a la libertad y a la seguridad, estableciendo garantías de la detención preventiva.',
     1),

    ('Constitución Española y Marco Jurídico Penitenciario',
     'La Ley Orgánica General Penitenciaria fue aprobada en el año:',
     '["1976","1977","1978","1979"]',
     '1979',
     'La LO 1/1979, de 26 de septiembre, General Penitenciaria, fue la primera ley orgánica aprobada tras la entrada en vigor de la Constitución de 1978.',
     1),

    ('Constitución Española y Marco Jurídico Penitenciario',
     'El Reglamento Penitenciario vigente está aprobado por:',
     '["RD 190/1996","RD 391/1996","RD 1201/1981","RD 84/2009"]',
     'RD 190/1996',
     'El Real Decreto 190/1996, de 9 de febrero, aprueba el Reglamento Penitenciario actualmente vigente.',
     2),

    ('Constitución Española y Marco Jurídico Penitenciario',
     'Según la CE, el condenado a pena de prisión tiene derecho a:',
     '["Perder todos sus derechos durante el cumplimiento","Conservar los derechos fundamentales no limitados por la condena","Ser sometido a cualquier tratamiento médico sin consentimiento","Renunciar a la asistencia letrada"]',
     'Conservar los derechos fundamentales no limitados por la condena',
     'El artículo 25.2 CE establece que el condenado conserva todos los derechos que no se vean expresamente limitados por el contenido del fallo condenatorio.',
     2),

    ('Constitución Española y Marco Jurídico Penitenciario',
     'El órgano encargado de la supervisión y control de la ejecución de las penas privativas de libertad es:',
     '["El Ministerio del Interior","El Juez de Vigilancia Penitenciaria","La Secretaría de Estado de Seguridad","El Ministerio de Justicia"]',
     'El Juez de Vigilancia Penitenciaria',
     'El Juez de Vigilancia Penitenciaria es el órgano jurisdiccional encargado de controlar la ejecución de las penas y garantizar los derechos de los internos.',
     2),

    ('Constitución Española y Marco Jurídico Penitenciario',
     'La institución penitenciaria en España depende orgánicamente de:',
     '["Ministerio de Justicia","Ministerio del Interior","Ministerio de Sanidad","Poder Judicial"]',
     'Ministerio del Interior',
     'La Secretaría General de Instituciones Penitenciarias depende del Ministerio del Interior, salvo en Cataluña que tiene competencias transferidas.',
     2),

    ('Constitución Española y Marco Jurídico Penitenciario',
     '¿Qué comunidad autónoma tiene transferidas las competencias en materia penitenciaria?',
     '["País Vasco","Navarra","Cataluña","Andalucía"]',
     'Cataluña',
     'Cataluña es la única comunidad autónoma con competencias ejecutivas en materia penitenciaria, gestionando sus propios centros a través del Departament de Justícia.',
     2),

    ('Constitución Española y Marco Jurídico Penitenciario',
     'La prohibición de la prisión provisional indefinida está amparada por:',
     '["El Reglamento Penitenciario","El artículo 17 CE y la Ley de Enjuiciamiento Criminal","La LOGP exclusivamente","El Código Penal"]',
     'El artículo 17 CE y la Ley de Enjuiciamiento Criminal',
     'El artículo 17 CE limita la duración de la detención y la LECrim regula los plazos máximos de la prisión provisional.',
     3),

    -- Tema 2: Ley Orgánica General Penitenciaria
    ('Ley Orgánica General Penitenciaria',
     'La Ley Orgánica General Penitenciaria se denomina:',
     '["LO 1/1978","LO 1/1979","LO 6/1984","LO 4/1981"]',
     'LO 1/1979',
     'La LO 1/1979, de 26 de septiembre, es la Ley Orgánica General Penitenciaria, primera ley orgánica del período constitucional.',
     1),

    ('Ley Orgánica General Penitenciaria',
     'Según la LOGP, la actividad penitenciaria se ejercerá respetando la personalidad humana de los recluidos y los derechos e intereses jurídicos no afectados por la condena. ¿En qué artículo se recoge este principio?',
     '["Artículo 1","Artículo 2","Artículo 3","Artículo 4"]',
     'Artículo 3',
     'El artículo 3 LOGP establece la obligación de respetar la personalidad humana de los internos y sus derechos no afectados por la condena.',
     2),

    ('Ley Orgánica General Penitenciaria',
     'Los establecimientos penitenciarios, según la LOGP, se clasifican en:',
     '["Preventivos, de cumplimiento y especiales","Cerrados, abiertos y semiabiertos","De máxima, media y mínima seguridad","Ordinarios y de régimen especial"]',
     'Preventivos, de cumplimiento y especiales',
     'El artículo 7 LOGP clasifica los establecimientos en preventivos (para presos), de cumplimiento de penas (para penados) y especiales (hospitales, psiquiátricos, etc.).',
     2),

    ('Ley Orgánica General Penitenciaria',
     'El principio de separación penitenciaria implica que:',
     '["Todos los internos comparten módulos sin distinción","Presos preventivos y penados deben estar separados","Solo se separa por sexo","La separación es voluntaria"]',
     'Presos preventivos y penados deben estar separados',
     'La LOGP establece el principio de separación: preventivos separados de penados, hombres de mujeres, jóvenes de adultos, primarios de reincidentes.',
     2),

    ('Ley Orgánica General Penitenciaria',
     'Según la LOGP, el régimen penitenciario comprende el conjunto de normas que regulan:',
     '["Solo la alimentación y el alojamiento","La convivencia y el orden dentro del establecimiento","Únicamente las sanciones disciplinarias","Los programas educativos"]',
     'La convivencia y el orden dentro del establecimiento',
     'El régimen penitenciario regula la convivencia y el orden en los establecimientos para crear el ambiente adecuado para el tratamiento.',
     2),

    ('Ley Orgánica General Penitenciaria',
     'Los permisos de salida ordinarios de hasta 7 días son concedidos por:',
     '["El director del centro","El Juez de Vigilancia Penitenciaria","La Junta de Tratamiento","La Secretaría General de II.PP."]',
     'La Junta de Tratamiento',
     'Los permisos de salida ordinarios son propuestos por la Junta de Tratamiento y autorizados según el régimen del interno, correspondiendo la resolución al centro directivo o al JVP.',
     3),

    ('Ley Orgánica General Penitenciaria',
     'El derecho de los internos a comunicarse con el exterior, según la LOGP, puede ser:',
     '["Suprimido definitivamente por razones de seguridad","Restringido o suspendido de forma motivada por el director","Ilimitado en todo caso","Solo oral, nunca escrito"]',
     'Restringido o suspendido de forma motivada por el director',
     'El artículo 51 LOGP regula las comunicaciones, permitiendo su restricción o suspensión motivada por el director por razones de seguridad.',
     3),

    ('Ley Orgánica General Penitenciaria',
     'La clasificación inicial de los penados en grado la realiza:',
     '["El juez sentenciador","El director del establecimiento","El centro directivo a propuesta de la Junta de Tratamiento","La Audiencia Provincial"]',
     'El centro directivo a propuesta de la Junta de Tratamiento',
     'El artículo 103 RP establece que la Junta de Tratamiento propone la clasificación inicial, que es aprobada por el centro directivo.',
     3),

    ('Ley Orgánica General Penitenciaria',
     'El tercer grado penitenciario corresponde al régimen:',
     '["Cerrado","Ordinario","Abierto","De semilibertad restrictiva"]',
     'Abierto',
     'El tercer grado habilita al interno para el régimen abierto, pudiendo realizar actividades en el exterior del centro bajo determinadas condiciones.',
     1),

    ('Ley Orgánica General Penitenciaria',
     'La libertad condicional, según el Código Penal vigente, se configura como:',
     '["Cuarto grado penitenciario","Suspensión de la ejecución del resto de la pena","Beneficio penitenciario potestativo","Reducción automática de condena"]',
     'Suspensión de la ejecución del resto de la pena',
     'Tras la reforma del CP de 2015, la libertad condicional se configura como una forma de suspensión de la ejecución del resto de la pena, no como un grado.',
     3),

    -- Tema 3: Reglamento Penitenciario y Régimen de Vida
    ('Reglamento Penitenciario y Régimen de Vida',
     'El Reglamento Penitenciario vigente fue aprobado por Real Decreto en el año:',
     '["1981","1990","1996","2001"]',
     '1996',
     'El RD 190/1996, de 9 de febrero, aprueba el Reglamento Penitenciario actualmente vigente.',
     1),

    ('Reglamento Penitenciario y Régimen de Vida',
     'El régimen cerrado se aplica a internos clasificados en:',
     '["Primer grado","Segundo grado","Tercer grado","Pendientes de clasificación"]',
     'Primer grado',
     'El primer grado determina la aplicación del régimen cerrado, para internos de peligrosidad extrema o inadaptación grave.',
     1),

    ('Reglamento Penitenciario y Régimen de Vida',
     'Los módulos de respeto son una modalidad organizativa del régimen:',
     '["Cerrado","Ordinario (segundo grado)","Abierto","Preventivo"]',
     'Ordinario (segundo grado)',
     'Los módulos de respeto son una modalidad de organización del régimen ordinario basada en la autogestión, el respeto y la responsabilidad de los internos.',
     3),

    ('Reglamento Penitenciario y Régimen de Vida',
     'Las unidades de madres en prisión permiten que los menores convivan con su madre interna hasta la edad de:',
     '["1 año","2 años","3 años","6 años"]',
     '3 años',
     'El artículo 178 RP establece que los hijos menores de 3 años podrán convivir con su madre en el establecimiento penitenciario.',
     2),

    ('Reglamento Penitenciario y Régimen de Vida',
     'El cacheo personal de los internos puede realizarse:',
     '["Solo con autorización judicial","Por el funcionario cuando existan razones de seguridad","Solo por el director del centro","Únicamente en presencia del médico"]',
     'Por el funcionario cuando existan razones de seguridad',
     'El artículo 68 RP permite al funcionario realizar cacheos con desnudo integral cuando existan razones de seguridad, de forma motivada y respetando la dignidad del interno.',
     2),

    ('Reglamento Penitenciario y Régimen de Vida',
     'Los departamentos especiales del régimen cerrado se caracterizan por:',
     '["Actividades en común durante al menos 16 horas diarias","Aislamiento en celda individual con salidas al patio de 2 a 3 horas","Libertad de movimiento total","Régimen comunitario intensivo"]',
     'Aislamiento en celda individual con salidas al patio de 2 a 3 horas',
     'Los departamentos especiales del primer grado implican aislamiento en celda con salidas al patio muy limitadas, como medida para internos de extrema peligrosidad.',
     3),

    ('Reglamento Penitenciario y Régimen de Vida',
     'El régimen abierto de tercer grado puede cumplirse en:',
     '["Solo en la prisión principal","Centros de inserción social (CIS)","Cualquier domicilio sin supervisión","Hospitales exclusivamente"]',
     'Centros de inserción social (CIS)',
     'Los internos de tercer grado pueden ser destinados a Centros de Inserción Social o cumplir el régimen abierto en sección abierta del establecimiento.',
     2),

    ('Reglamento Penitenciario y Régimen de Vida',
     'Las comunicaciones vis a vis son las que se realizan:',
     '["Por carta","Por teléfono","En locutorio sin separación física","Por videoconferencia"]',
     'En locutorio sin separación física',
     'Las comunicaciones vis a vis son las comunicaciones íntimas sin separación física entre el interno y sus familiares o allegados.',
     1),

    ('Reglamento Penitenciario y Régimen de Vida',
     'La sanción de aislamiento en celda no podrá exceder de:',
     '["7 días","14 días","21 días","42 días en caso de graves alteraciones del orden"]',
     '14 días',
     'El artículo 42 LOGP y el RP establecen que el aislamiento en celda como sanción no puede exceder de 14 días consecutivos.',
     2),

    ('Reglamento Penitenciario y Régimen de Vida',
     'El expediente disciplinario en un centro penitenciario es instruido por:',
     '["El Juez de Vigilancia Penitenciaria","Un funcionario designado por el director","La Junta de Tratamiento","La Audiencia Provincial"]',
     'Un funcionario designado por el director',
     'El director designa a un funcionario como instructor del expediente disciplinario, garantizando la audiencia del interno y el derecho de defensa.',
     2),

    -- Tema 4: Tratamiento Penitenciario e Intervención
    ('Tratamiento Penitenciario e Intervención',
     'El tratamiento penitenciario tiene como fin:',
     '["El castigo del delincuente","La reeducación y reinserción social del interno","La seguridad de la sociedad mediante el aislamiento","La reparación económica a las víctimas"]',
     'La reeducación y reinserción social del interno',
     'El artículo 59 LOGP define el tratamiento como el conjunto de actividades orientadas a la reeducación y reinserción social de los internos.',
     1),

    ('Tratamiento Penitenciario e Intervención',
     'La participación del interno en el tratamiento penitenciario es:',
     '["Obligatoria bajo sanción","Voluntaria","Solo obligatoria para penados por delitos graves","Impuesta por el juez sentenciador"]',
     'Voluntaria',
     'El artículo 61 LOGP establece que el tratamiento se basa en el principio de voluntariedad del interno, aunque su participación activa es valorada positivamente.',
     2),

    ('Tratamiento Penitenciario e Intervención',
     'La Junta de Tratamiento está presidida por:',
     '["El Juez de Vigilancia Penitenciaria","El director del establecimiento","El subdirector de tratamiento","El médico del centro"]',
     'El director del establecimiento',
     'La Junta de Tratamiento es un órgano colegiado presidido por el director e integrado por los distintos profesionales que intervienen en el tratamiento.',
     2),

    ('Tratamiento Penitenciario e Intervención',
     'El programa PRIA-MA en el ámbito penitenciario está dirigido a:',
     '["Personas con adicción a drogas","Agresores de pareja y violencia de género","Internos con trastornos mentales graves","Menores infractores"]',
     'Agresores de pareja y violencia de género',
     'El PRIA-MA (Programa de Intervención para Agresores en violencia de género) es uno de los programas de tratamiento más extendidos en los centros penitenciarios.',
     3),

    ('Tratamiento Penitenciario e Intervención',
     'El trabajo de los internos en los centros penitenciarios se considera:',
     '["Una sanción añadida a la pena","Un elemento del tratamiento y un derecho-deber del interno","Voluntario solo para penados de tercer grado","Obligatorio únicamente para deudas con la administración"]',
     'Un elemento del tratamiento y un derecho-deber del interno',
     'El artículo 26 LOGP configura el trabajo como derecho y deber del interno, elemento del tratamiento orientado a la reinserción.',
     2),

    ('Tratamiento Penitenciario e Intervención',
     'Los programas de deshabituación de drogas en prisión son coordinados principalmente con:',
     '["Cruz Roja exclusivamente","Organismos públicos de drogodependencias y ONG colaboradoras","La Policía Nacional","El Ministerio de Sanidad de forma directa"]',
     'Organismos públicos de drogodependencias y ONG colaboradoras',
     'Los planes de atención a drogodependientes se desarrollan en coordinación con los servicios autonómicos de drogodependencias y entidades colaboradoras.',
     2),

    ('Tratamiento Penitenciario e Intervención',
     'La Unidad Terapéutica y Educativa (UTE) es un modelo de intervención basado en:',
     '["El aislamiento y reflexión individual","La comunidad terapéutica y la autogestión responsable","El trabajo forzado como terapia","La medicación psiquiátrica como único tratamiento"]',
     'La comunidad terapéutica y la autogestión responsable',
     'Las UTE son módulos diferenciados basados en el modelo de comunidad terapéutica, donde los propios internos participan activamente en la gestión y el tratamiento.',
     3),

    ('Tratamiento Penitenciario e Intervención',
     'La formación educativa en prisión incluye, como mínimo garantizado:',
     '["Formación universitaria","Educación básica (alfabetización y educación primaria)","Solo formación profesional","Cursos de idiomas obligatorios"]',
     'Educación básica (alfabetización y educación primaria)',
     'El artículo 55 LOGP garantiza la educación básica a los internos, especialmente a los analfabetos, como derecho fundamental.',
     2),

    ('Tratamiento Penitenciario e Intervención',
     'El Plan Individualizado de Tratamiento (PIT) es elaborado por:',
     '["El Juez de Vigilancia Penitenciaria","La Junta de Tratamiento","El interno de forma autónoma","El Ministerio del Interior"]',
     'La Junta de Tratamiento',
     'La Junta de Tratamiento elabora el programa individualizado de tratamiento para cada interno, estableciendo objetivos, actividades y evaluación del progreso.',
     2),

    ('Tratamiento Penitenciario e Intervención',
     'Los beneficios penitenciarios como el adelantamiento de la libertad condicional requieren:',
     '["Solo el tiempo mínimo de condena cumplido","Participación activa en actividades de tratamiento y buena conducta","Solicitud del abogado defensor","Autorización del juez sentenciador"]',
     'Participación activa en actividades de tratamiento y buena conducta',
     'Los beneficios penitenciarios se conceden valorando la evolución en el tratamiento, la conducta, y los informes del equipo técnico.',
     3),

    -- Tema 5: Seguridad, Disciplina y Organización del Centro
    ('Seguridad, Disciplina y Organización del Centro',
     'Las faltas disciplinarias de los internos se clasifican en:',
     '["Leves y graves","Muy graves, graves y leves","Menores, intermedias y mayores","Solo graves y leves"]',
     'Muy graves, graves y leves',
     'El artículo 108 RP clasifica las infracciones disciplinarias en muy graves, graves y leves, con sanciones proporcionales a su gravedad.',
     1),

    ('Seguridad, Disciplina y Organización del Centro',
     'El uso de medios coercitivos por parte de los funcionarios penitenciarios:',
     '["Puede aplicarse libremente a criterio del funcionario","Solo está permitido como último recurso y de forma proporcionada","Está completamente prohibido","Requiere siempre autorización judicial previa"]',
     'Solo está permitido como último recurso y de forma proporcionada',
     'El artículo 45 LOGP regula los medios coercitivos estableciendo que solo pueden usarse cuando otros medios de control no sean eficaces, de forma proporcionada.',
     2),

    ('Seguridad, Disciplina y Organización del Centro',
     '¿Qué órgano colegiado gestiona el régimen de vida del establecimiento y resuelve expedientes disciplinarios?',
     '["La Junta de Tratamiento","La Comisión Disciplinaria","El Consejo de Dirección","El Juez de Vigilancia Penitenciaria"]',
     'La Comisión Disciplinaria',
     'La Comisión Disciplinaria es el órgano colegiado del establecimiento encargado de resolver los expedientes disciplinarios incoados a los internos.',
     2),

    ('Seguridad, Disciplina y Organización del Centro',
     'El cacheo con desnudo integral de un interno puede realizarse cuando:',
     '["Sea solicitado por el propio interno","Existan razones de seguridad que lo justifiquen, de forma motivada","Sea rutina diaria del establecimiento","Lo ordene el Juez de Vigilancia"]',
     'Existan razones de seguridad que lo justifiquen, de forma motivada',
     'El RP permite el cacheo integral solo cuando existan razones fundadas de seguridad, debiendo realizarse con respeto a la dignidad y de forma motivada.',
     2),

    ('Seguridad, Disciplina y Organización del Centro',
     'El parte de incidencias en un centro penitenciario es elaborado por:',
     '["El equipo de tratamiento","El funcionario de servicio que observe la incidencia","La dirección exclusivamente","El Juez de Vigilancia"]',
     'El funcionario de servicio que observe la incidencia',
     'El parte de incidencias es el documento por el que el funcionario de servicio comunica a la dirección cualquier hecho relevante para el orden y la seguridad.',
     1),

    ('Seguridad, Disciplina y Organización del Centro',
     'Las intervenciones de comunicaciones escritas de los internos deben ser autorizadas por:',
     '["El director del establecimiento","El Juez de Vigilancia Penitenciaria","La Secretaría General de II.PP.","El subdirector de seguridad"]',
     'El Juez de Vigilancia Penitenciaria',
     'La intervención de comunicaciones escritas requiere autorización del Juez de Vigilancia Penitenciaria, como garantía del derecho al secreto de las comunicaciones.',
     3),

    ('Seguridad, Disciplina y Organización del Centro',
     'El personal del Cuerpo de Ayudantes de Instituciones Penitenciarias pertenece a:',
     '["Grupo A1 de la función pública","Grupo C1 de la función pública","Grupo B de la función pública","Grupo A2 de la función pública"]',
     'Grupo C1 de la función pública',
     'Los Ayudantes de IIPP pertenecen al Subgrupo C1 de los funcionarios de la Administración General del Estado.',
     2),

    ('Seguridad, Disciplina y Organización del Centro',
     'La organización de la vigilancia en un centro penitenciario está a cargo del:',
     '["Director","Subdirector de Seguridad","Jefe de Servicios","Juez de Vigilancia Penitenciaria"]',
     'Jefe de Servicios',
     'El Jefe de Servicios es el responsable de organizar el servicio de vigilancia interior, coordinando a los funcionarios del turno.',
     2),

    ('Seguridad, Disciplina y Organización del Centro',
     'La sanción de aislamiento en celda durante fines de semana se aplica como sanción de falta:',
     '["Muy grave","Grave","Leve","No existe este tipo de sanción"]',
     'Grave',
     'El artículo 232 RP incluye el aislamiento en celda durante fines de semana como una de las sanciones aplicables a faltas graves.',
     3),

    ('Seguridad, Disciplina y Organización del Centro',
     'Ante una situación de motín en un establecimiento penitenciario, la primera actuación del funcionario debe ser:',
     '["Intervenir físicamente de inmediato","Dar la alarma y comunicar a los mandos según el protocolo","Evacuar a todos los internos al patio","Negociar directamente con los líderes del motín"]',
     'Dar la alarma y comunicar a los mandos según el protocolo',
     'El protocolo de actuación ante incidentes graves establece que la primera acción es activar la alarma y comunicar a los mandos para activar el plan de emergencia.',
     2)

),
temas_ref AS (
    SELECT t.id, t.nombre
    FROM temas t
    JOIN ramas_oposiciones r ON t.rama_id = r.id
    WHERE r.nombre = 'Cuerpo de Ayudantes de II.PP. (Prisiones)'
)
INSERT INTO preguntas (tema_id, enunciado, tipo, opciones, respuesta_correcta, explicacion, dificultad)
SELECT tr.id, p.enunciado, 'MCQ', p.opciones::jsonb, p.respuesta_correcta, p.explicacion, p.dificultad
FROM preguntas_prisiones p
JOIN temas_ref tr ON tr.nombre = p.tema_nombre;

-- ══════════════════════════════════════════════════════════════════════════════
-- 3) TEMAS — FUERZAS ARMADAS
-- ══════════════════════════════════════════════════════════════════════════════

INSERT INTO temas (rama_id, nombre, orden, descripcion_corta, preguntas_count)
SELECT r.id, v.nombre, v.orden, v.descripcion, 10
FROM ramas_oposiciones r
JOIN (VALUES
    ('Constitución Española y Defensa Nacional',     1, 'CE y marco constitucional de la defensa: artículos 8, 30 y 97'),
    ('Organización de las Fuerzas Armadas',          2, 'Estructura orgánica: Ejército de Tierra, Armada, Ejército del Aire y del Espacio'),
    ('Carrera Militar y Acceso a las FAS',           3, 'Ley 39/2007: escalas, empleos, acceso y sistema de enseñanza militar'),
    ('Régimen Disciplinario de las FAS',             4, 'LO 8/2014: infracciones, sanciones y procedimiento disciplinario'),
    ('Ética Militar y Valores de las FAS',           5, 'Reales Ordenanzas (RD 96/2009): valores, deberes y conducta del militar')
) AS v(nombre, orden, descripcion) ON 1=1
WHERE r.nombre = 'Fuerzas Armadas';

UPDATE ramas_oposiciones SET temas_count = 5
WHERE nombre = 'Fuerzas Armadas';

-- ── Preguntas — Fuerzas Armadas ───────────────────────────────────────────────

WITH preguntas_ffaa (tema_nombre, enunciado, opciones, respuesta_correcta, explicacion, dificultad) AS (
    VALUES

    -- Tema 1: Constitución Española y Defensa Nacional
    ('Constitución Española y Defensa Nacional',
     'Según el artículo 8 de la Constitución Española, las Fuerzas Armadas tienen como misiones:',
     '["Garantizar el orden público interior","Defender la soberanía, la independencia territorial e integridad territorial y el ordenamiento constitucional","Gestionar situaciones de emergencia civil exclusivamente","Apoyar la política exterior del Gobierno"]',
     'Defender la soberanía, la independencia territorial e integridad territorial y el ordenamiento constitucional',
     'El artículo 8.1 CE establece las tres misiones constitucionales de las FAS: defensa de la soberanía e independencia, integridad territorial y defensa del ordenamiento constitucional.',
     1),

    ('Constitución Española y Defensa Nacional',
     '¿Quién ostenta el mando supremo de las Fuerzas Armadas según la Constitución?',
     '["El Presidente del Gobierno","El Rey","El Ministro de Defensa","El Jefe del Estado Mayor de la Defensa"]',
     'El Rey',
     'El artículo 62.h CE atribuye al Rey el mando supremo de las Fuerzas Armadas.',
     1),

    ('Constitución Española y Defensa Nacional',
     'La Ley Orgánica de la Defensa Nacional es la:',
     '["LO 5/2005","LO 6/1980","Ley 39/2007","LO 8/2014"]',
     'LO 5/2005',
     'La LO 5/2005, de 17 de noviembre, de la Defensa Nacional, regula los criterios básicos de la defensa nacional y la organización militar.',
     1),

    ('Constitución Española y Defensa Nacional',
     'Según el artículo 30 de la Constitución, la defensa de España:',
     '["Es un derecho y un deber de los españoles","Es responsabilidad exclusiva del Ejército profesional","Solo compete a los ciudadanos varones mayores de 18 años","No está regulada en la Constitución"]',
     'Es un derecho y un deber de los españoles',
     'El artículo 30 CE establece que los españoles tienen el derecho y el deber de defender a España. La prestación del servicio militar se regula por ley.',
     1),

    ('Constitución Española y Defensa Nacional',
     'El Consejo de Defensa Nacional es el órgano superior:',
     '["Ejecutivo en materia de defensa","Asesor y consultivo del Presidente del Gobierno en materia de defensa","Legislativo en materia militar","Jurisdiccional de las Fuerzas Armadas"]',
     'Asesor y consultivo del Presidente del Gobierno en materia de defensa',
     'Según la LO 5/2005, el Consejo de Defensa Nacional es el órgano colegiado, coordinador y asesor del Presidente del Gobierno en materia de defensa.',
     2),

    ('Constitución Española y Defensa Nacional',
     'El Jefe del Estado Mayor de la Defensa (JEMAD) es el:',
     '["Máximo responsable de cada ejército","Jefe superior de las FAS bajo la autoridad del Ministro de Defensa","Asesor directo del Rey en asuntos militares","Comandante operativo de las FAS bajo la autoridad del Presidente del Gobierno"]',
     'Jefe superior de las FAS bajo la autoridad del Ministro de Defensa',
     'El JEMAD es el jefe superior del personal militar de las FAS, bajo la autoridad del Ministro de Defensa, responsable de la eficacia operativa de las FAS.',
     2),

    ('Constitución Española y Defensa Nacional',
     'España suspendió el servicio militar obligatorio en el año:',
     '["1996","1999","2001","2002"]',
     '2001',
     'El servicio militar obligatorio quedó suspendido en España el 31 de diciembre de 2001, pasando a un modelo de fuerzas armadas totalmente profesionales.',
     2),

    ('Constitución Española y Defensa Nacional',
     'La dirección de la política de defensa corresponde al:',
     '["Rey","Congreso de los Diputados","Gobierno y en especial al Presidente","Jefatura del Estado Mayor"]',
     'Gobierno y en especial al Presidente',
     'El artículo 97 CE y la LO 5/2005 atribuyen al Gobierno, y especialmente al Presidente, la dirección de la política de defensa.',
     2),

    ('Constitución Española y Defensa Nacional',
     'Las misiones de las FAS en el exterior requieren autorización previa de:',
     '["Solo del Gobierno","El Congreso de los Diputados","El Senado","El JEMAD con visto bueno del Ministro de Defensa"]',
     'El Congreso de los Diputados',
     'Según la LO 5/2005, las operaciones en el exterior que no sean respuesta a agresión armada requieren autorización previa del Congreso de los Diputados.',
     3),

    ('Constitución Española y Defensa Nacional',
     'El concepto de "objeción de conciencia" en relación con el servicio militar en España:',
     '["Está actualmente vigente como alternativa al servicio activo","Es irrelevante al estar suspendido el servicio militar obligatorio","Está prohibido por la Constitución","Solo aplica en tiempos de guerra"]',
     'Es irrelevante al estar suspendido el servicio militar obligatorio',
     'Con la suspensión del servicio militar obligatorio en 2001, la objeción de conciencia carece de aplicación práctica actual, aunque su reconocimiento constitucional persiste.',
     3),

    -- Tema 2: Organización de las Fuerzas Armadas
    ('Organización de las Fuerzas Armadas',
     'Las Fuerzas Armadas españolas están compuestas por:',
     '["Ejército de Tierra y Armada","Ejército de Tierra, Armada y Ejército del Aire y del Espacio","Ejército de Tierra, Marina, Aviación y Guardia Civil","Solo el Ejército de Tierra"]',
     'Ejército de Tierra, Armada y Ejército del Aire y del Espacio',
     'Las FAS españolas están integradas por el Ejército de Tierra, la Armada y el Ejército del Aire y del Espacio (denominación actualizada).',
     1),

    ('Organización de las Fuerzas Armadas',
     'El Ejército del Aire pasó a denominarse oficialmente "Ejército del Aire y del Espacio" en el año:',
     '["2019","2020","2021","2022"]',
     '2021',
     'El cambio de denominación se hizo efectivo en 2021 para reflejar las nuevas responsabilidades en el dominio espacial.',
     2),

    ('Organización de las Fuerzas Armadas',
     'El Cuartel General de las Fuerzas Armadas (EMACON) depende del:',
     '["Ejército de Tierra","Ministerio del Interior","JEMAD","Presidente del Gobierno directamente"]',
     'JEMAD',
     'El Estado Mayor Conjunto de la Defensa (EMACON) es el órgano auxiliar del JEMAD para el planeamiento y el control estratégico.',
     3),

    ('Organización de las Fuerzas Armadas',
     'La Brigada Paracaidista (BRIPAC) pertenece al:',
     '["Ejército del Aire","Ejército de Tierra","Armada","Guardia Civil"]',
     'Ejército de Tierra',
     'La Brigada Paracaidista es una unidad de élite del Ejército de Tierra especializada en operaciones aerotransportadas.',
     2),

    ('Organización de las Fuerzas Armadas',
     'La Infantería de Marina es una fuerza perteneciente a:',
     '["Ejército de Tierra","Ejército del Aire y del Espacio","Armada","Guardia Civil"]',
     'Armada',
     'La Infantería de Marina es el cuerpo de combate terrestre de la Armada española, especializado en operaciones anfibias.',
     1),

    ('Organización de las Fuerzas Armadas',
     'La Unidad Militar de Emergencias (UME) tiene como misión principal:',
     '["Combate en el exterior","Intervención en situaciones de grave riesgo, catástrofe o calamidad pública","Vigilancia de fronteras","Apoyo logístico a las FAS"]',
     'Intervención en situaciones de grave riesgo, catástrofe o calamidad pública',
     'La UME fue creada en 2005 para intervenir en situaciones de emergencia grave en territorio nacional, colaborando con las autoridades civiles.',
     1),

    ('Organización de las Fuerzas Armadas',
     'Las Fuerzas Armadas españolas participan en misiones de la OTAN bajo el principio de:',
     '["Mando nacional exclusivo","Mando integrado y defensa colectiva (Art. 5 del Tratado de Washington)","Autonomía total de cada contingente","Supervisión exclusiva del Parlamento Europeo"]',
     'Mando integrado y defensa colectiva (Art. 5 del Tratado de Washington)',
     'España, como miembro de la OTAN desde 1982, participa en la estructura de mando integrado y está comprometida con la defensa colectiva del Art. 5.',
     2),

    ('Organización de las Fuerzas Armadas',
     'El rango de Soldado o Marinero corresponde a la categoría de:',
     '["Oficial","Suboficial","Tropa y marinería","Oficial general"]',
     'Tropa y marinería',
     'La categoría de tropa y marinería comprende los empleos de Soldado/Marinero, Soldado de Primera/Marinero de Primera y Cabo/Cabo de Mar.',
     1),

    ('Organización de las Fuerzas Armadas',
     'El acceso a las FAS en la escala de tropa y marinería profesional permanente requiere superar:',
     '["Solo la prueba física","Proceso selectivo con pruebas físicas, psicotécnicas y médicas","Solo un examen teórico","Únicamente la formación previa en academia"]',
     'Proceso selectivo con pruebas físicas, psicotécnicas y médicas',
     'El acceso a las FAS requiere superar un proceso selectivo que incluye valoración médica, pruebas físicas y psicotécnicas según la convocatoria.',
     1),

    ('Organización de las Fuerzas Armadas',
     'El Mando de Operaciones (MOPS) es responsable de:',
     '["La formación de los reclutas","El planeamiento y conducción de las operaciones militares","La logística y abastecimiento","La administración del personal"]',
     'El planeamiento y conducción de las operaciones militares',
     'El Mando de Operaciones es el órgano del JEMAD responsable del planeamiento, dirección y conducción de las operaciones militares.',
     3),

    -- Tema 3: Carrera Militar y Acceso a las FAS
    ('Carrera Militar y Acceso a las FAS',
     'La Ley de la Carrera Militar es la:',
     '["LO 5/2005","Ley 39/2007","LO 8/2014","RD 96/2009"]',
     'Ley 39/2007',
     'La Ley 39/2007, de 19 de noviembre, de la Carrera Militar, regula el sistema de enseñanza, la carrera profesional y el régimen del personal militar.',
     1),

    ('Carrera Militar y Acceso a las FAS',
     'Los militares de tropa y marinería pueden acceder a la condición de militar de carrera mediante:',
     '["Antigüedad automática","Promoción interna a través de la enseñanza militar de formación","Designación directa del mando","Solo mediante oposición libre externa"]',
     'Promoción interna a través de la enseñanza militar de formación',
     'La Ley 39/2007 contempla la promoción interna como vía para que los militares de tropa y marinería puedan acceder a la escala de suboficiales.',
     2),

    ('Carrera Militar y Acceso a las FAS',
     'La edad máxima para el acceso como tropa o marinería profesional es, con carácter general:',
     '["25 años","28 años","30 años","35 años"]',
     '29 años',
     'Con carácter general, el límite de edad para el acceso como tropa y marinería profesional es de 29 años, aunque puede variar según convocatoria.',
     2),

    ('Carrera Militar y Acceso a las FAS',
     'El compromiso inicial de los militares de tropa y marinería profesional tiene una duración mínima de:',
     '["1 año","2 años","3 años","5 años"]',
     '2 años',
     'El compromiso inicial mínimo de los militares de tropa y marinería es de 2 años, prorrogables según la normativa vigente.',
     2),

    ('Carrera Militar y Acceso a las FAS',
     'La enseñanza militar de formación para el acceso como oficial se imparte en:',
     '["Las universidades civiles","Los centros de enseñanza militar (academias militares)","Cualquier centro oficial de formación","Solo en el extranjero mediante convenios"]',
     'Los centros de enseñanza militar (academias militares)',
     'La formación para el acceso como oficial de los distintos ejércitos se imparte en las academias militares correspondientes (AGM, ENM, AGA).',
     1),

    ('Carrera Militar y Acceso a las FAS',
     'El empleo de Sargento corresponde a la escala de:',
     '["Tropa y marinería","Suboficiales","Oficiales","Oficiales generales"]',
     'Suboficiales',
     'La escala de suboficiales comprende los empleos de Sargento, Sargento Primero, Brigada, Subteniente y Suboficial Mayor.',
     1),

    ('Carrera Militar y Acceso a las FAS',
     'El periodo de prácticas de los militares de complemento se realiza:',
     '["Antes de la formación académica","Tras superar la formación en el centro de enseñanza militar","Solo en unidades en el exterior","Durante la fase de selección"]',
     'Tras superar la formación en el centro de enseñanza militar',
     'Los militares de complemento, tras la formación académica, realizan un periodo de prácticas en unidades antes de adquirir la plena capacidad operativa.',
     3),

    ('Carrera Militar y Acceso a las FAS',
     'La evaluación periódica del personal militar tiene como objetivos:',
     '["Solo la detección de faltas disciplinarias","La valoración del rendimiento y la decisión sobre continuidad, ascenso o destino","La asignación de remuneración exclusivamente","La planificación de bajas voluntarias"]',
     'La valoración del rendimiento y la decisión sobre continuidad, ascenso o destino',
     'Las evaluaciones son el instrumento para valorar las aptitudes, rendimiento y condiciones del militar, con efectos en ascensos, destinos y continuidad.',
     2),

    ('Carrera Militar y Acceso a las FAS',
     'El acceso al Cuerpo de Suboficiales del Ejército de Tierra se realiza principalmente a través de:',
     '["La Academia General Militar de Zaragoza","La Academia de Suboficiales del Ejército de Tierra en Talarn (Lleida)","Cualquier escuela de formación profesional civil","El Instituto Nacional de Administración Pública"]',
     'La Academia de Suboficiales del Ejército de Tierra en Talarn (Lleida)',
     'La formación de suboficiales del Ejército de Tierra se imparte en la Academia de Suboficiales ubicada en Talarn, Lleida.',
     3),

    ('Carrera Militar y Acceso a las FAS',
     'La edad de retiro forzoso de los militares de carrera en los empleos más elevados (generales) es de:',
     '["60 años","65 años","67 años","70 años"]',
     '67 años',
     'La Ley 39/2007 establece diferentes edades de retiro según el empleo, siendo la edad máxima general de 67 años para los empleos más elevados.',
     3),

    -- Tema 4: Régimen Disciplinario de las FAS
    ('Régimen Disciplinario de las FAS',
     'La Ley del Régimen Disciplinario de las Fuerzas Armadas es la:',
     '["LO 5/2005","Ley 39/2007","LO 8/2014","RD 96/2009"]',
     'LO 8/2014',
     'La LO 8/2014, de 4 de diciembre, del Régimen Disciplinario de las Fuerzas Armadas, regula las infracciones, sanciones y procedimientos disciplinarios.',
     1),

    ('Régimen Disciplinario de las FAS',
     'Las infracciones disciplinarias en las FAS se clasifican en:',
     '["Leves y graves","Muy graves, graves y leves","Solo graves","Menores, mayores y extraordinarias"]',
     'Muy graves, graves y leves',
     'La LO 8/2014 clasifica las infracciones en muy graves, graves y leves, con sanciones proporcionales a su gravedad.',
     1),

    ('Régimen Disciplinario de las FAS',
     'La sanción de separación del servicio solo puede imponerse por faltas:',
     '["Leves reiteradas","Graves","Muy graves","Graves y muy graves indistintamente"]',
     'Muy graves',
     'La separación del servicio es la sanción más grave prevista en la LO 8/2014 y solo puede imponerse como consecuencia de infracciones muy graves.',
     2),

    ('Régimen Disciplinario de las FAS',
     'El principio de jerarquía en el ámbito disciplinario militar implica que:',
     '["Los subordinados no pueden reclamar ante sanciones injustas","El mando tiene facultad disciplinaria sobre sus subordinados, con límites legales","Las sanciones son inapelables","Solo los oficiales pueden imponer sanciones"]',
     'El mando tiene facultad disciplinaria sobre sus subordinados, con límites legales',
     'El principio de jerarquía atribuye al mando la facultad disciplinaria, pero sujeta a los límites y garantías de la LO 8/2014.',
     2),

    ('Régimen Disciplinario de las FAS',
     'El arresto en unidad como sanción disciplinaria implica:',
     '["Privación de libertad en prisión militar","Restricción de movimientos y permanencia en el acuartelamiento fuera de servicio","Reducción de sueldo temporal","Baja temporal del servicio"]',
     'Restricción de movimientos y permanencia en el acuartelamiento fuera de servicio',
     'El arresto en unidad restringe la libertad de movimientos del sancionado, que debe permanecer en el acuartelamiento durante su tiempo libre.',
     2),

    ('Régimen Disciplinario de las FAS',
     'La prescripción de las faltas leves en el régimen disciplinario de las FAS es de:',
     '["1 mes","2 meses","6 meses","1 año"]',
     '2 meses',
     'Las faltas leves prescriben a los 2 meses, las graves a los 2 años y las muy graves a los 5 años según la LO 8/2014.',
     3),

    ('Régimen Disciplinario de las FAS',
     'El derecho del expedientado a ser asistido por un asesor en el procedimiento disciplinario:',
     '["No existe en el ámbito militar","Está reconocido en la LO 8/2014","Solo aplica en procedimientos por faltas muy graves ante el Tribunal Militar","Requiere autorización del mando"]',
     'Está reconocido en la LO 8/2014',
     'La LO 8/2014 reconoce al expedientado el derecho a ser asistido por un asesor de su elección durante el procedimiento disciplinario.',
     2),

    ('Régimen Disciplinario de las FAS',
     'Las sanciones disciplinarias militares pueden ser recurridas ante:',
     '["Solo ante el mando superior","La jurisdicción contencioso-administrativa","La jurisdicción penal militar exclusivamente","El Tribunal Constitucional directamente"]',
     'La jurisdicción contencioso-administrativa',
     'Las resoluciones disciplinarias militares son recurribles ante la jurisdicción contencioso-administrativa, tras agotar la vía administrativa.',
     3),

    ('Régimen Disciplinario de las FAS',
     'La falta de respeto o desconsideración hacia un superior constituye, con carácter general, una falta:',
     '["Leve","Grave","Muy grave","No está tipificada"]',
     'Grave',
     'La LO 8/2014 tipifica la falta de respeto a superiores, en función de la gravedad y circunstancias, generalmente como falta grave.',
     2),

    ('Régimen Disciplinario de las FAS',
     'El procedimiento sancionador por faltas leves en las FAS se caracteriza por ser:',
     '["Igual al de las faltas graves con expediente completo","Sumario, con menor formalismo pero garantizando audiencia al interesado","Sin posibilidad de recurso","Exclusivamente oral sin constancia escrita"]',
     'Sumario, con menor formalismo pero garantizando audiencia al interesado',
     'El procedimiento por faltas leves es simplificado, pero la LO 8/2014 exige siempre audiencia al interesado como garantía mínima.',
     3),

    -- Tema 5: Ética Militar y Valores de las FAS
    ('Ética Militar y Valores de las FAS',
     'Las Reales Ordenanzas para las Fuerzas Armadas están aprobadas por:',
     '["LO 5/2005","Ley 39/2007","RD 96/2009","LO 8/2014"]',
     'RD 96/2009',
     'Las Reales Ordenanzas para las Fuerzas Armadas fueron aprobadas por Real Decreto 96/2009, de 6 de febrero.',
     1),

    ('Ética Militar y Valores de las FAS',
     'Los valores que las Reales Ordenanzas definen como fundamentales para el militar son:',
     '["Obediencia, valentía y disciplina","Disciplina, jerarquía y abnegación","Lealtad, disciplina y valor","Honor, valor y lealtad a la Constitución"]',
     'Lealtad, disciplina y valor',
     'Las Reales Ordenanzas establecen como valores fundamentales del militar la lealtad, la disciplina y el valor, junto con el honor y la abnegación.',
     2),

    ('Ética Militar y Valores de las FAS',
     'La obediencia debida en las FAS tiene como límite:',
     '["No tiene límites, es absoluta","Las órdenes manifiestamente ilegales o contrarias a la dignidad humana","Solo las órdenes que pongan en riesgo la propia vida","Las instrucciones del sindicato militar"]',
     'Las órdenes manifiestamente ilegales o contrarias a la dignidad humana',
     'Las Reales Ordenanzas y la LO 8/2014 establecen que el militar debe obedecer las órdenes legítimas, pero tiene el deber de abstenerse de ejecutar órdenes manifiestamente ilegales.',
     2),

    ('Ética Militar y Valores de las FAS',
     'El concepto de "honor militar" implica:',
     '["Buscar el reconocimiento personal por encima del bien común","Actuar con rectitud, honestidad y fidelidad a los valores y deberes militares","Solo la conducta ejemplar en combate","El mantenimiento de las tradiciones del ejército"]',
     'Actuar con rectitud, honestidad y fidelidad a los valores y deberes militares',
     'El honor militar se configura como el compromiso con los valores y principios que definen la profesión militar, manifestándose en conducta íntegra en todo momento.',
     2),

    ('Ética Militar y Valores de las FAS',
     'El derecho de asociación de los militares profesionales en España:',
     '["Es idéntico al del resto de ciudadanos sin restricciones","Está limitado: solo pueden asociarse en asociaciones profesionales, no en sindicatos","Está totalmente prohibido","Solo se permite para oficiales"]',
     'Está limitado: solo pueden asociarse en asociaciones profesionales, no en sindicatos',
     'La Constitución y la legislación militar limitan el derecho de sindicación de los militares, permitiendo asociaciones profesionales con fines no sindicales.',
     3),

    ('Ética Militar y Valores de las FAS',
     'La neutralidad política de los militares implica que:',
     '["No pueden votar en elecciones","Deben abstenerse de participar en actividades políticas y manifestar opiniones que puedan comprometer la neutralidad de las FAS","No pueden afiliarse a ningún partido ni expresar ninguna opinión","Solo es obligatoria durante el servicio activo"]',
     'Deben abstenerse de participar en actividades políticas y manifestar opiniones que puedan comprometer la neutralidad de las FAS',
     'Las Reales Ordenanzas y la legislación militar imponen neutralidad política activa, prohibiendo actividades que comprometan la imagen institucional de las FAS.',
     2),

    ('Ética Militar y Valores de las FAS',
     'El principio de abnegación en la ética militar supone:',
     '["Preferir el interés personal sobre el colectivo","Anteponer el cumplimiento del deber al propio bienestar","Obedecer sin cuestionar ninguna orden","Renunciar a todos los derechos personales"]',
     'Anteponer el cumplimiento del deber al propio bienestar',
     'La abnegación implica la disposición a sacrificar el interés personal en aras del cumplimiento del deber y del bien común, valor central en la ética militar.',
     2),

    ('Ética Militar y Valores de las FAS',
     'El trato digno entre militares y hacia la población civil está regulado:',
     '["Solo por el Código Penal","Por las Reales Ordenanzas, la legislación internacional humanitaria y el reglamento interno","Únicamente por el derecho internacional","Solo durante misiones en el exterior"]',
     'Por las Reales Ordenanzas, la legislación internacional humanitaria y el reglamento interno',
     'El trato digno es un principio transversal regulado por las Ordenanzas, el Derecho Internacional Humanitario y la normativa interna, aplicable en todo contexto.',
     2),

    ('Ética Militar y Valores de las FAS',
     'La responsabilidad del mando implica que el oficial o suboficial al mando es responsable de:',
     '["Solo sus propias acciones directas","Las acciones de sus subordinados en el cumplimiento de las misiones encomendadas","Los errores únicamente si ha dado orden expresa","Nada, si el subordinado actuó por iniciativa propia"]',
     'Las acciones de sus subordinados en el cumplimiento de las misiones encomendadas',
     'El principio de responsabilidad del mando establece que el jefe responde del empleo de sus subordinados y del resultado de las misiones asignadas.',
     3),

    ('Ética Militar y Valores de las FAS',
     'Según las Reales Ordenanzas, ante una situación de peligro grave el militar debe:',
     '["Retirarse para proteger su integridad","Actuar con serenidad y valor, anteponiendo el cumplimiento de la misión","Esperar siempre la orden del superior antes de actuar","Consultar el reglamento antes de decidir"]',
     'Actuar con serenidad y valor, anteponiendo el cumplimiento de la misión',
     'Las Ordenanzas exigen al militar que ante situaciones de peligro actúe con serenidad, valor y sentido de la responsabilidad, priorizando el cumplimiento del deber.',
     2)

),
temas_ref AS (
    SELECT t.id, t.nombre
    FROM temas t
    JOIN ramas_oposiciones r ON t.rama_id = r.id
    WHERE r.nombre = 'Fuerzas Armadas'
)
INSERT INTO preguntas (tema_id, enunciado, tipo, opciones, respuesta_correcta, explicacion, dificultad)
SELECT tr.id, p.enunciado, 'MCQ', p.opciones::jsonb, p.respuesta_correcta, p.explicacion, p.dificultad
FROM preguntas_ffaa p
JOIN temas_ref tr ON tr.nombre = p.tema_nombre;

-- ══════════════════════════════════════════════════════════════════════════════
-- 4) ACTUALIZAR preguntas_count EN TEMAS
-- ══════════════════════════════════════════════════════════════════════════════

UPDATE temas t
SET preguntas_count = (SELECT COUNT(*) FROM preguntas p WHERE p.tema_id = t.id)
FROM ramas_oposiciones r
WHERE t.rama_id = r.id
  AND r.nombre IN ('Cuerpo de Ayudantes de II.PP. (Prisiones)', 'Fuerzas Armadas');
