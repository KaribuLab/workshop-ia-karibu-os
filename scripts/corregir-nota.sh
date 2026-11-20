#!/bin/bash
# Corrige un dato dentro de una nota, sin tocar el resto del texto.
#
#   scripts/corregir-nota.sh "<título o letra de la nota>" "<texto actual>" "<texto nuevo>"
#
# Ejemplo:
#   scripts/corregir-nota.sh "Reembolso de gastos médicos" "60 días" "90 días"
#
# El <texto actual> debe aparecer exactamente una vez en la nota. Si no
# aparece, o aparece más de una vez, no cambia nada y avisa.
set -euo pipefail
. "$(dirname "$0")/_entorno.sh"

if [ "$#" -ne 3 ]; then
    echo 'Uso: scripts/corregir-nota.sh "<título o letra>" "<texto actual>" "<texto nuevo>"' >&2
    exit 2
fi

nota="$1"; actual="$2"; nuevo="$3"

if [ -z "$actual" ]; then
    echo "El texto actual no puede estar vacío." >&2
    exit 2
fi
if [ "$actual" = "$nuevo" ]; then
    echo "El texto actual y el nuevo son iguales: no hay nada que corregir." >&2
    exit 2
fi

listar_notas() {
    consulta -F ' | ' <<'SQL'
SELECT 'Nota ' || codigo, titulo FROM notas ORDER BY nota_id;
SQL
}

# 1. Ubicar la nota: primero por letra o título completo; si no, por una parte
#    del título, siempre que coincida con una sola nota.
nota_id="$(consulta -v nota="$nota" <<'SQL'
SELECT nota_id FROM notas
WHERE upper(codigo) = upper(btrim(:'nota')) OR lower(titulo) = lower(btrim(:'nota'))
LIMIT 1;
SQL
)"

if [ -z "$nota_id" ]; then
    parecidas="$(consulta -v nota="$nota" <<'SQL'
SELECT nota_id FROM notas
WHERE strpos(sin_tildes(titulo), sin_tildes(:'nota')) > 0
ORDER BY nota_id;
SQL
)"
    if [ -z "$parecidas" ]; then
        echo "No encontré una nota llamada \"$nota\". No se cambió nada. Notas que existen:"
        listar_notas
        exit 1
    fi
    if [ "$(printf '%s\n' "$parecidas" | wc -l)" -ne 1 ]; then
        echo "Más de una nota coincide con \"$nota\". No se cambió nada. Indica la letra o el título completo:"
        listar_notas
        exit 1
    fi
    nota_id="$parecidas"
fi

# 2. El texto a reemplazar debe aparecer exactamente una vez.
veces="$(consulta -v id="$nota_id" -v actual="$actual" <<'SQL'
SELECT (length(contenido) - length(replace(contenido, :'actual', ''))) / length(:'actual')
FROM notas WHERE nota_id = :'id'::integer;
SQL
)"

if [ "$veces" = "0" ]; then
    echo "El texto \"$actual\" no aparece en la nota. No se cambió nada. La nota dice hoy:"
    echo
    consulta -v id="$nota_id" <<'SQL'
SELECT contenido FROM notas WHERE nota_id = :'id'::integer;
SQL
    exit 1
fi
if [ "$veces" != "1" ]; then
    echo "El texto \"$actual\" aparece $veces veces en la nota. No se cambió nada."
    echo "Usa un fragmento más largo, que aparezca una sola vez."
    exit 1
fi

# 3. Corregir. La autoría y la fecha las pone la base.
resultado="$(consulta -F ' | ' -v id="$nota_id" -v actual="$actual" -v nuevo="$nuevo" <<'SQL'
UPDATE notas
SET contenido = overlay(contenido PLACING :'nuevo'
                        FROM strpos(contenido, :'actual') FOR length(:'actual'))
WHERE nota_id = :'id'::integer
  AND (length(contenido) - length(replace(contenido, :'actual', ''))) / length(:'actual') = 1
RETURNING 'Nota corregida', 'Nota ' || codigo, titulo,
          'corregida por ' || actualizado_por,
          to_char(actualizado_en AT TIME ZONE 'America/Santiago', 'DD-MM-YYYY HH24:MI');
SQL
)"

if [ -z "$resultado" ]; then
    echo "Otra persona cambió la nota recién y el texto \"$actual\" ya no aparece una sola vez. No se cambió nada."
    exit 1
fi
echo "$resultado"
