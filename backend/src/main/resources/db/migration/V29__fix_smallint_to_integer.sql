-- Hibernate 6 mapea Java int/Integer -> JDBC INTEGER (type 4).
-- Java Double -> JDBC DOUBLE (float8).
-- V28 creó estas columnas con tipos incompatibles con la validación estricta de Hibernate 6.
-- Todos son widenings seguros sin pérdida de datos.

-- sesiones_repaso
ALTER TABLE sesiones_repaso ALTER COLUMN total_preguntas TYPE INTEGER;
ALTER TABLE sesiones_repaso ALTER COLUMN correctas TYPE INTEGER;
ALTER TABLE sesiones_repaso ALTER COLUMN puntuacion TYPE DOUBLE PRECISION;

-- respuestas_sesion_repaso
ALTER TABLE respuestas_sesion_repaso ALTER COLUMN pregunta_index TYPE INTEGER;
ALTER TABLE respuestas_sesion_repaso ALTER COLUMN respuesta_usuario TYPE INTEGER;
