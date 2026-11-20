#!/bin/bash
# Rol de los participantes. La contraseña llega por WORKSHOP_RW_PASSWORD
# (la misma que cada workspace recibe como POSTGRES_PASS); nunca se imprime.
#
# workshop_rw puede leer y modificar los datos de negocio, pero no puede
# cambiar la estructura, vaciar tablas, tocar la bitácora ni restaurar.
set -euo pipefail
: "${WORKSHOP_RW_PASSWORD:?WORKSHOP_RW_PASSWORD requerida para crear workshop_rw}"

psql -v ON_ERROR_STOP=1 -v rw_password="$WORKSHOP_RW_PASSWORD" -v db="$POSTGRES_DB" \
  --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<'SQL'
CREATE ROLE workshop_rw WITH LOGIN PASSWORD :'rw_password';

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT CONNECT ON DATABASE :"db" TO workshop_rw;
GRANT USAGE ON SCHEMA public TO workshop_rw;

GRANT SELECT, INSERT, UPDATE ON equipos, personas, proyectos, compromisos, riesgos TO workshop_rw;
GRANT DELETE ON compromisos, riesgos TO workshop_rw;
GRANT SELECT ON bitacora TO workshop_rw;
SQL
echo "[init] rol workshop_rw creado"
