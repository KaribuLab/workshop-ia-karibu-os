-- Copia de las notas de partida para poder volver al inicio sin reiniciar la
-- base. El esquema "semilla" no es visible para los participantes.

CREATE SCHEMA semilla;
CREATE TABLE semilla.notas AS TABLE public.notas;

-- Devuelve las notas al punto de partida (sin la nota nueva ni las
-- correcciones), vacía la bitácora y cierra todas las sesiones.
-- No toca sueldos ni claves: los participantes no pueden modificarlos.
-- Uso (solo administrador):  SELECT restaurar_datos();
CREATE FUNCTION restaurar_datos() RETURNS text
LANGUAGE plpgsql SET search_path = public, pg_temp AS $$
BEGIN
    TRUNCATE notas, bitacora, sesiones, accesos RESTART IDENTITY;
    ALTER TABLE notas DISABLE TRIGGER USER;
    INSERT INTO notas SELECT * FROM semilla.notas;
    ALTER TABLE notas ENABLE TRIGGER USER;
    PERFORM setval(pg_get_serial_sequence('notas', 'nota_id'), (SELECT max(nota_id) FROM notas));
    RETURN 'Datos restaurados al punto de partida';
END;
$$;

REVOKE ALL ON FUNCTION restaurar_datos() FROM PUBLIC;
REVOKE ALL ON SCHEMA semilla FROM PUBLIC;
