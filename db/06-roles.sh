#!/bin/bash
# Rol de los participantes. La contraseña llega por WORKSHOP_RW_PASSWORD
# (la misma que cada workspace recibe como POSTGRES_PASS); nunca se imprime.
#
# workshop_rw puede leer, crear y corregir notas, y ver quién cambió cada una
# (vista cambios_notas). No puede borrarlas, cambiar la estructura, leer la
# bitácora completa ni restaurar. No tiene ningún permiso sobre
# sueldos, credenciales, sesiones ni accesos: a los sueldos solo se llega por
# las funciones de 05-acceso.sql, con RUT y clave.
set -euo pipefail
: "${WORKSHOP_RW_PASSWORD:?WORKSHOP_RW_PASSWORD requerida para crear workshop_rw}"

psql -v ON_ERROR_STOP=1 -v rw_password="$WORKSHOP_RW_PASSWORD" -v db="$POSTGRES_DB" \
  --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<'SQL'
CREATE ROLE workshop_rw WITH LOGIN PASSWORD :'rw_password';

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT CONNECT ON DATABASE :"db" TO workshop_rw;
GRANT USAGE ON SCHEMA public TO workshop_rw;

GRANT SELECT ON personas, cambios_notas TO workshop_rw;
GRANT SELECT ON notas TO workshop_rw;
-- Solo las columnas de contenido: la letra, el id y la autoría las pone la base.
GRANT INSERT (titulo, area, responsable, contenido),
      UPDATE (titulo, area, responsable, contenido) ON notas TO workshop_rw;

GRANT EXECUTE ON FUNCTION iniciar_sesion(text, text), cerrar_sesion(uuid),
                          quien_soy(uuid), ver_sueldo(uuid, text) TO workshop_rw;
SQL
echo "[init] rol workshop_rw creado"
