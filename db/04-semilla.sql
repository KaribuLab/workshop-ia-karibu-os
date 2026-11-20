-- Copia del seed para poder volver al punto de partida sin reiniciar la base.
-- El esquema "semilla" no es visible para los participantes.

CREATE SCHEMA semilla;
CREATE TABLE semilla.equipos     AS TABLE public.equipos;
CREATE TABLE semilla.personas    AS TABLE public.personas;
CREATE TABLE semilla.proyectos   AS TABLE public.proyectos;
CREATE TABLE semilla.compromisos AS TABLE public.compromisos;
CREATE TABLE semilla.riesgos     AS TABLE public.riesgos;

-- Devuelve las tablas de negocio al seed y vacía la bitácora.
-- Uso (solo administrador):  SELECT restaurar_datos();
CREATE FUNCTION restaurar_datos() RETURNS text
LANGUAGE plpgsql SET search_path = public, pg_temp AS $$
DECLARE
    t text;
BEGIN
    TRUNCATE riesgos, compromisos, proyectos, personas, equipos, bitacora RESTART IDENTITY;
    FOREACH t IN ARRAY ARRAY['equipos', 'personas', 'proyectos', 'compromisos', 'riesgos'] LOOP
        EXECUTE format('ALTER TABLE %I DISABLE TRIGGER USER', t);
        EXECUTE format('INSERT INTO %I SELECT * FROM semilla.%I', t, t);
        EXECUTE format('ALTER TABLE %I ENABLE TRIGGER USER', t);
    END LOOP;
    PERFORM setval(pg_get_serial_sequence('equipos',     'equipo_id'),     (SELECT max(equipo_id)     FROM equipos));
    PERFORM setval(pg_get_serial_sequence('personas',    'persona_id'),    (SELECT max(persona_id)    FROM personas));
    PERFORM setval(pg_get_serial_sequence('proyectos',   'proyecto_id'),   (SELECT max(proyecto_id)   FROM proyectos));
    PERFORM setval(pg_get_serial_sequence('compromisos', 'compromiso_id'), (SELECT max(compromiso_id) FROM compromisos));
    PERFORM setval(pg_get_serial_sequence('riesgos',     'riesgo_id'),     (SELECT max(riesgo_id)     FROM riesgos));
    RETURN 'Datos restaurados al punto de partida';
END;
$$;

REVOKE ALL ON FUNCTION restaurar_datos() FROM PUBLIC;
REVOKE ALL ON SCHEMA semilla FROM PUBLIC;
