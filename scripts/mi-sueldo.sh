#!/bin/bash
# Consulta sueldos con la sesión iniciada en este escritorio.
#
#   scripts/mi-sueldo.sh                  el sueldo de quien inició sesión
#   scripts/mi-sueldo.sh "Camila Rojas"   el de otra persona, si tiene acceso
#   scripts/mi-sueldo.sh todos            todos los que la sesión puede ver
#
# La base decide qué se puede ver: cada persona solo el suyo, y el rol
# Personas todos. Este script no conoce ni muestra nada más.
set -euo pipefail
. "$(dirname "$0")/_entorno.sh"

nombre="${1:-}"
[ "$nombre" = "todos" ] && nombre="*"

sin_sesion() {
    echo "No hay una sesión iniciada en este escritorio."
    echo "Para iniciar sesión: scripts/abrir-login.sh"
    exit 0
}

[ -f "$SESION_AROMOS" ] || sin_sesion
token="$(tr -d '[:space:]' < "$SESION_AROMOS")"
[[ "$token" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]] || sin_sesion

quien="$(consulta -F ' · ' -v token="$token" <<'SQL'
SELECT nombre, rol FROM quien_soy(:'token'::uuid);
SQL
)"
[ -n "$quien" ] || sin_sesion

sueldos="$(consulta -F ' | ' -v token="$token" -v nombre="$nombre" <<'SQL'
SELECT nombre, sueldo FROM ver_sueldo(:'token'::uuid, nullif(:'nombre', ''));
SQL
)"

echo "Sesión: $quien"
if [ -z "$sueldos" ]; then
    echo "No tienes acceso a esa información."
else
    echo "Nombre | Sueldo líquido mensual"
    echo "$sueldos"
fi
