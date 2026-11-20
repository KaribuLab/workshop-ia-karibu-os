-- Autoría y bitácora automáticas. "Quién" es el application_name de la
-- conexión, que el workspace fija con el nombre de usuario del participante.
-- Es atribución, no seguridad: sirve para saber quién cambió qué.

CREATE FUNCTION usuario_actual() RETURNS text
LANGUAGE sql STABLE AS $$
    SELECT coalesce(nullif(current_setting('application_name', true), ''), session_user::text);
$$;

-- Antes de guardar una nota: la base asigna la letra y la autoría. Lo que
-- mande el participante en esas columnas se ignora.
CREATE FUNCTION preparar_nota() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    v_n integer;
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Una nota nueva a la vez, para no repetir letra entre participantes.
        PERFORM pg_advisory_xact_lock(hashtext('notas.codigo'));
        -- Siguiente número después del mayor existente (A=1 ... Z=26, N27...),
        -- no la cantidad de notas: si se borra una, no se repite letra.
        SELECT coalesce(max(CASE WHEN codigo ~ '^[A-Z]$' THEN ascii(codigo) - 64
                                 WHEN codigo ~ '^N[0-9]+$' THEN substr(codigo, 2)::integer
                            END), 0) + 1
        INTO v_n FROM notas;
        NEW.codigo          := CASE WHEN v_n <= 26 THEN chr(64 + v_n) ELSE 'N' || v_n END;
        NEW.creado_por      := usuario_actual();
        NEW.creado_en       := now();
        NEW.actualizado_por := NEW.creado_por;
        NEW.actualizado_en  := NEW.creado_en;
    ELSE
        NEW.codigo     := OLD.codigo;
        NEW.creado_por := OLD.creado_por;
        NEW.creado_en  := OLD.creado_en;
        IF (NEW.titulo, NEW.area, NEW.responsable, NEW.contenido)
           IS DISTINCT FROM (OLD.titulo, OLD.area, OLD.responsable, OLD.contenido) THEN
            NEW.actualizado_por := usuario_actual();
            NEW.actualizado_en  := now();
        ELSE
            NEW.actualizado_por := OLD.actualizado_por;
            NEW.actualizado_en  := OLD.actualizado_en;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER notas_preparar BEFORE INSERT OR UPDATE ON notas
    FOR EACH ROW EXECUTE FUNCTION preparar_nota();

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
        usuario_actual(),
        TG_TABLE_NAME,
        TG_OP,
        (coalesce(v_despues, v_antes) ->> TG_ARGV[0])::integer,
        v_antes,
        v_despues
    );
    RETURN NULL;
END;
$$;

CREATE TRIGGER bitacora_notas AFTER INSERT OR UPDATE OR DELETE ON notas
    FOR EACH ROW EXECUTE FUNCTION registrar_bitacora('nota_id');

-- Lo que los participantes ven de la bitácora: quién cambió qué nota y cuándo
-- (hora de Chile). No muestra el texto anterior: una vez corregido un dato,
-- nadie vuelve a ver el valor viejo. La bitácora completa, con "antes" y
-- "despues", queda para el administrador.
CREATE VIEW cambios_notas AS
SELECT b.bitacora_id,
       to_char(b.ocurrido_en AT TIME ZONE 'America/Santiago', 'DD-MM-YYYY HH24:MI') AS cuando,
       b.usuario AS quien,
       CASE b.operacion WHEN 'INSERT' THEN 'creó la nota'
                        WHEN 'UPDATE' THEN 'corrigió la nota'
                        ELSE 'eliminó la nota' END AS que_hizo,
       coalesce(b.despues, b.antes) ->> 'codigo' AS nota,
       coalesce(b.despues, b.antes) ->> 'titulo' AS titulo
FROM bitacora b
WHERE b.tabla = 'notas';

-- Las tablas con llave no llevan bitácora: "antes" y "despues" guardan la
-- fila completa y dejarían los sueldos a la vista de todos.
-- El seed se cargó antes de crear los triggers, así que la bitácora parte vacía.
