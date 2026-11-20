-- Bitácora automática: cada cambio en una tabla de negocio deja una fila con
-- quién lo hizo. "Quién" es el application_name de la conexión, que el
-- workspace fija con el nombre de usuario del participante.
--
-- SECURITY DEFINER: los participantes no pueden escribir en bitacora
-- directamente; solo este trigger lo hace por ellos.

CREATE FUNCTION registrar_bitacora() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
    v_antes   jsonb := CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) END;
    v_despues jsonb := CASE WHEN TG_OP IN ('UPDATE', 'INSERT') THEN to_jsonb(NEW) END;
BEGIN
    IF TG_OP = 'UPDATE' AND v_antes = v_despues THEN
        RETURN NULL;  -- update que no cambió nada: no ensuciar la bitácora
    END IF;
    INSERT INTO bitacora (usuario, tabla, operacion, fila_id, antes, despues)
    VALUES (
        coalesce(nullif(current_setting('application_name', true), ''), session_user),
        TG_TABLE_NAME,
        TG_OP,
        (coalesce(v_despues, v_antes) ->> TG_ARGV[0])::integer,
        v_antes,
        v_despues
    );
    RETURN NULL;
END;
$$;

CREATE TRIGGER bitacora_equipos     AFTER INSERT OR UPDATE OR DELETE ON equipos
    FOR EACH ROW EXECUTE FUNCTION registrar_bitacora('equipo_id');
CREATE TRIGGER bitacora_personas    AFTER INSERT OR UPDATE OR DELETE ON personas
    FOR EACH ROW EXECUTE FUNCTION registrar_bitacora('persona_id');
CREATE TRIGGER bitacora_proyectos   AFTER INSERT OR UPDATE OR DELETE ON proyectos
    FOR EACH ROW EXECUTE FUNCTION registrar_bitacora('proyecto_id');
CREATE TRIGGER bitacora_compromisos AFTER INSERT OR UPDATE OR DELETE ON compromisos
    FOR EACH ROW EXECUTE FUNCTION registrar_bitacora('compromiso_id');
CREATE TRIGGER bitacora_riesgos     AFTER INSERT OR UPDATE OR DELETE ON riesgos
    FOR EACH ROW EXECUTE FUNCTION registrar_bitacora('riesgo_id');

-- El seed se cargó antes de crear los triggers, así que la bitácora parte vacía.
