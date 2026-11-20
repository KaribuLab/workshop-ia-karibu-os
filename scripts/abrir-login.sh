#!/bin/bash
# Abre la página local de inicio de sesión de Aseguradora Los Aromos.
# Si la página no está corriendo, la levanta primero. Solo responde dentro
# de este escritorio (127.0.0.1).
set -euo pipefail
. "$(dirname "$0")/_entorno.sh"

repo="$(cd "$(dirname "$0")/.." && pwd)"
puerto="${LOGIN_PUERTO:-8765}"
url="http://127.0.0.1:${puerto}/"

responde() {
    curl -fs -o /dev/null --max-time 2 "${url}salud"
}

if ! responde; then
    LOGIN_PUERTO="$puerto" nohup setsid python3 "$repo/pagina/servidor.py" \
        >"$HOME/.login-aromos.log" 2>&1 </dev/null &
    for _ in $(seq 1 40); do
        responde && break
        sleep 0.25
    done
fi

if ! responde; then
    echo "No se pudo levantar la página de inicio de sesión. Detalle en $HOME/.login-aromos.log"
    exit 1
fi

# En el escritorio del workshop se abre Chromium como ventana propia. Dentro
# del contenedor no hay sandbox de Chromium (igual que en OpenCode Desktop):
# sin --no-sandbox no abre. Sin navegador no es un error: se muestra la dirección.
if [ "${LOGIN_NO_ABRIR:-}" != "1" ]; then
    if command -v chromium >/dev/null 2>&1; then
        (setsid chromium --no-sandbox --disable-dev-shm-usage --no-first-run \
            --user-data-dir="$HOME/.config/login-aromos" --window-size=960,660 --app="$url" >/dev/null 2>&1 &)
    elif command -v xdg-open >/dev/null 2>&1; then
        (xdg-open "$url" >/dev/null 2>&1 &)
    fi
fi
echo "Página de inicio de sesión: $url"
