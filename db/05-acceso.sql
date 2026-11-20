-- La llave de los sueldos. Los participantes comparten un mismo usuario de
-- base, así que la restricción no puede depender de ese usuario ni de lo que
-- el agente decida mostrar: vive aquí, en funciones que validan RUT + clave.
--
-- SECURITY DEFINER: estas funciones leen tablas a las que el participante no
-- tiene acceso, y devuelven solo lo que le corresponde.

-- Para comparar nombres sin importar mayúsculas ni tildes.
CREATE FUNCTION sin_tildes(p text) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
    SELECT translate(lower(btrim(p)), 'áéíóúüñ', 'aeiouun');
$$;

-- "11.111.111-1", "11111111-1" y "111111111" son el mismo RUT.
CREATE FUNCTION normalizar_rut(p text) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
    SELECT upper(regexp_replace(coalesce(p, ''), '[^0-9kK]', '', 'g'));
$$;

CREATE FUNCTION hash_clave(p_sal text, p_clave text) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
    SELECT encode(sha256(convert_to(p_sal || p_clave, 'UTF8')), 'hex');
$$;

-- Inicia sesión. Devuelve siempre una fila:
--   estado = 'ok'     con token, nombre y rol
--   estado = 'fallo'  RUT o clave incorrectos (no dice cuál de los dos)
--
-- Freno a la fuerza bruta: los intentos para un mismo RUT pasan de a uno y
-- cada uno espera medio segundo ANTES de revisar la clave, acierte o no.
-- Así nadie prueba más de 2 claves por segundo para una persona, aunque abra
-- muchas conexiones. No se usa un contador de fallos: cualquier fila que se
-- escriba aquí se puede deshacer con ROLLBACK, el tiempo no. Esperar antes de
-- revisar evita que cortar la consulta a tiempo (statement_timeout) delate
-- si la clave era correcta. Tampoco bloquea a nadie: en el paso 13 todos
-- prueban el RUT de Paula con una clave falsa y ella igual debe poder entrar.
CREATE FUNCTION iniciar_sesion(p_rut text, p_clave text)
RETURNS TABLE (estado text, token uuid, nombre text, rol text)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
    v_usuario text := usuario_actual();
    v_rut     text := normalizar_rut(p_rut);
    v_persona personas%ROWTYPE;
    v_token   uuid;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext('iniciar_sesion:' || v_rut));
    PERFORM pg_sleep(0.5);

    SELECT p.* INTO v_persona
    FROM personas p
    JOIN credenciales c USING (persona_id)
    WHERE normalizar_rut(p.rut) = v_rut
      AND c.clave_hash = hash_clave(c.sal, coalesce(p_clave, ''));

    -- Registro de intentos, solo para revisar después (no frena nada).
    IF NOT FOUND THEN
        INSERT INTO accesos (usuario, rut, resultado) VALUES (v_usuario, v_rut, 'fallo');
        RETURN QUERY SELECT 'fallo'::text, NULL::uuid, NULL::text, NULL::text;
        RETURN;
    END IF;

    INSERT INTO sesiones (persona_id, usuario, expira_en)
    VALUES (v_persona.persona_id, v_usuario, now() + interval '8 hours')
    RETURNING sesiones.token INTO v_token;
    INSERT INTO accesos (usuario, rut, resultado) VALUES (v_usuario, v_rut, 'ok');

    RETURN QUERY SELECT 'ok'::text, v_token, v_persona.nombre, v_persona.rol;
END;
$$;

CREATE FUNCTION cerrar_sesion(p_token uuid) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
    DELETE FROM sesiones WHERE token = p_token;
    RETURN FOUND;
END;
$$;

-- Quién es el dueño de una sesión vigente. Sin filas si no existe o venció.
CREATE FUNCTION quien_soy(p_token uuid)
RETURNS TABLE (nombre text, cargo text, rol text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT p.nombre, p.cargo, p.rol
    FROM sesiones s JOIN personas p USING (persona_id)
    WHERE s.token = p_token AND s.expira_en > now();
$$;

-- Sueldos que la sesión puede ver.
--   p_nombre NULL  -> el propio
--   p_nombre '*'   -> todos los que puede ver (solo el suyo, salvo Personas)
--   p_nombre texto -> esa persona, si le corresponde verla
-- Si no le corresponde, devuelve cero filas: igual que si la persona no
-- existiera, para no dar pistas.
CREATE FUNCTION ver_sueldo(p_token uuid, p_nombre text DEFAULT NULL)
RETURNS TABLE (nombre text, sueldo text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    WITH yo AS (
        SELECT p.persona_id, p.rol
        FROM sesiones s JOIN personas p USING (persona_id)
        WHERE s.token = p_token AND s.expira_en > now()
    )
    SELECT p.nombre, su.sueldo
    FROM yo
    JOIN personas p ON yo.rol = 'Personas' OR p.persona_id = yo.persona_id
    JOIN sueldos su ON su.persona_id = p.persona_id
    WHERE CASE
            WHEN p_nombre IS NULL THEN p.persona_id = yo.persona_id
            WHEN btrim(p_nombre) = '*' THEN true
            ELSE strpos(sin_tildes(p.nombre), sin_tildes(p_nombre)) > 0
          END
    ORDER BY p.nombre;
$$;

-- Carga la clave y el sueldo de una persona. Solo administrador.
-- Uso:  SELECT cargar_ficha('11.111.111-1', '<clave>', '$1.150.000');
CREATE FUNCTION cargar_ficha(p_rut text, p_clave text, p_sueldo text) RETURNS text
LANGUAGE plpgsql SET search_path = public, pg_temp AS $$
DECLARE
    v_persona personas%ROWTYPE;
    v_sal     text := gen_random_uuid()::text;
BEGIN
    SELECT * INTO v_persona FROM personas WHERE normalizar_rut(rut) = normalizar_rut(p_rut);
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe una persona con RUT %', p_rut;
    END IF;
    -- Con 2 intentos por segundo como máximo, una clave de 10 caracteres
    -- no adivinable no se alcanza a descubrir durante un workshop.
    IF length(coalesce(p_clave, '')) < 10 THEN
        RAISE EXCEPTION 'La clave debe tener al menos 10 caracteres';
    END IF;

    INSERT INTO credenciales (persona_id, sal, clave_hash)
    VALUES (v_persona.persona_id, v_sal, hash_clave(v_sal, p_clave))
    ON CONFLICT (persona_id) DO UPDATE SET sal = EXCLUDED.sal, clave_hash = EXCLUDED.clave_hash;

    INSERT INTO sueldos (persona_id, sueldo)
    VALUES (v_persona.persona_id, p_sueldo)
    ON CONFLICT (persona_id) DO UPDATE SET sueldo = EXCLUDED.sueldo;

    -- Una clave nueva invalida las sesiones abiertas con la anterior.
    DELETE FROM sesiones WHERE persona_id = v_persona.persona_id;

    RETURN 'Ficha cargada: ' || v_persona.nombre;
END;
$$;

-- Nadie ejecuta estas funciones salvo quien reciba permiso en 06-roles.sh.
REVOKE ALL ON FUNCTION iniciar_sesion(text, text)      FROM PUBLIC;
REVOKE ALL ON FUNCTION cerrar_sesion(uuid)             FROM PUBLIC;
REVOKE ALL ON FUNCTION quien_soy(uuid)                 FROM PUBLIC;
REVOKE ALL ON FUNCTION ver_sueldo(uuid, text)          FROM PUBLIC;
REVOKE ALL ON FUNCTION cargar_ficha(text, text, text)  FROM PUBLIC;
