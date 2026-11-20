# Se carga desde los demás scripts (no se ejecuta solo).
# Deja lista la conexión a la base y define el archivo de la sesión.

# En el escritorio del workshop la conexión viene en /config/.workshop-env.
if [ -z "${PGHOST:-}" ] && [ -f /config/.workshop-env ]; then
    . /config/.workshop-env
fi

# Donde la página de inicio de sesión guarda la sesión de este escritorio.
SESION_AROMOS="${SESION_AROMOS:-$HOME/.sesion-aromos}"
export SESION_AROMOS

# psql sin configuración personal, sin adornos y que se detenga al primer error.
consulta() {
    psql -X -q -A -t -v ON_ERROR_STOP=1 "$@"
}
