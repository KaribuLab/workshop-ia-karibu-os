#!/bin/bash
# Guarda una nota en la memoria del equipo (tabla notas).
#
#   scripts/guardar-nota.sh "<título>" "<área>" "<responsable>" <archivo>
#
#   <área>     Siniestros, Comercial o Personas
#   <archivo>  texto completo de la nota; "-" para leerlo de la entrada estándar
#
# Si ya existe una nota con ese título, la reemplaza (queda en la bitácora).
# La letra de la nota (A, B, C...) y la autoría las asigna la base.
set -euo pipefail
. "$(dirname "$0")/_entorno.sh"

if [ "$#" -ne 4 ]; then
    echo 'Uso: scripts/guardar-nota.sh "<título>" "<área>" "<responsable>" <archivo>' >&2
    exit 2
fi

titulo="$1"; area="$2"; responsable="$3"; archivo="$4"

case "$area" in
    Siniestros|Comercial|Personas) ;;
    *) echo "Área no válida: \"$area\". Usa Siniestros, Comercial o Personas." >&2; exit 2 ;;
esac

if [ "$archivo" = "-" ]; then
    contenido="$(cat)"
elif [ -f "$archivo" ]; then
    contenido="$(cat "$archivo")"
else
    echo "No existe el archivo: $archivo" >&2
    exit 2
fi

if [ -z "${titulo// /}" ] || [ -z "${responsable// /}" ] || [ -z "${contenido//[[:space:]]/}" ]; then
    echo "Faltan datos: el título, el responsable y el contenido no pueden estar vacíos." >&2
    exit 2
fi

# Si otra persona ya guardó exactamente la misma nota, no hay nada que hacer.
igual="$(consulta -F ' | ' \
    -v titulo="$titulo" -v area="$area" -v responsable="$responsable" -v contenido="$contenido" <<'SQL'
SELECT 'La nota ya estaba guardada, sin cambios', 'Nota ' || codigo, titulo,
       'guardada por ' || actualizado_por,
       to_char(actualizado_en AT TIME ZONE 'America/Santiago', 'DD-MM-YYYY HH24:MI')
FROM notas
WHERE lower(titulo) = lower(btrim(:'titulo')) AND area = :'area'
  AND responsable = btrim(:'responsable') AND contenido = :'contenido';
SQL
)"
if [ -n "$igual" ]; then
    echo "$igual"
    exit 0
fi

consulta -F ' | ' \
    -v titulo="$titulo" -v area="$area" -v responsable="$responsable" -v contenido="$contenido" <<'SQL'
INSERT INTO notas (titulo, area, responsable, contenido)
VALUES (btrim(:'titulo'), :'area', btrim(:'responsable'), :'contenido')
ON CONFLICT (lower(titulo)) DO UPDATE
    SET area = EXCLUDED.area, responsable = EXCLUDED.responsable, contenido = EXCLUDED.contenido
RETURNING CASE WHEN xmax = 0 THEN 'Nota creada' ELSE 'Nota reemplazada' END,
          'Nota ' || codigo, titulo, 'área ' || area, 'responsable ' || responsable,
          'guardada por ' || actualizado_por,
          to_char(actualizado_en AT TIME ZONE 'America/Santiago', 'DD-MM-YYYY HH24:MI');
SQL
