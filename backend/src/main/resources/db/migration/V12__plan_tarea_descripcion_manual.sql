-- Añade columna para descripciones personalizadas en tareas manuales.
-- Las tareas generadas por IA dejan esta columna NULL y usan la descripción dinámica del servicio.
ALTER TABLE plan_tareas ADD COLUMN descripcion VARCHAR(200);

-- Flag para distinguir tareas creadas manualmente por el usuario de las generadas por IA.
ALTER TABLE plan_tareas ADD COLUMN manual BOOLEAN NOT NULL DEFAULT FALSE;
