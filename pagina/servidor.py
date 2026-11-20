#!/usr/bin/env python3
"""Página local de inicio de sesión de Aseguradora Los Aromos.

Valida RUT + clave contra la base (función iniciar_sesion) y deja la sesión
de este escritorio en un archivo que usa scripts/mi-sueldo.sh.

La página no decide nada: quién entra y qué puede ver lo resuelve la base.
Solo usa la librería estándar de Python y el comando psql.
Se levanta con scripts/abrir-login.sh.
"""

import html
import os
import re
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs

PUERTO = int(os.environ.get("LOGIN_PUERTO", "8765"))
ARCHIVO_SESION = os.environ.get(
    "SESION_AROMOS", os.path.join(os.path.expanduser("~"), ".sesion-aromos")
)
TOKEN_VALIDO = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)
SEPARADOR = "\x1f"

MENSAJES = {
    "fallo": "RUT o clave incorrectos.",
    "error": "No se pudo consultar la base. Avisa al presentador.",
    "incompleto": "Escribe tu RUT y tu clave.",
}


def consulta(sql, **variables):
    """Ejecuta SQL con psql. Los valores viajan como variables, nunca pegados al SQL."""
    comando = ["psql", "-X", "-q", "-A", "-t", "-F", SEPARADOR, "-v", "ON_ERROR_STOP=1"]
    for nombre, valor in variables.items():
        comando += ["-v", f"{nombre}={valor}"]
    resultado = subprocess.run(
        comando, input=sql, capture_output=True, text=True, timeout=15
    )
    if resultado.returncode != 0:
        raise RuntimeError(resultado.stderr.strip())
    return [linea.split(SEPARADOR) for linea in resultado.stdout.splitlines() if linea]


def leer_token():
    try:
        with open(ARCHIVO_SESION, encoding="utf-8") as archivo:
            token = archivo.read().strip()
    except OSError:
        return None
    return token if TOKEN_VALIDO.match(token) else None


def guardar_token(token):
    descriptor = os.open(ARCHIVO_SESION, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(descriptor, "w", encoding="utf-8") as archivo:
        archivo.write(token + "\n")
    os.chmod(ARCHIVO_SESION, 0o600)


def borrar_token():
    try:
        os.remove(ARCHIVO_SESION)
    except OSError:
        pass


def sesion_actual():
    """Devuelve (nombre, cargo, rol) de la sesión vigente, o None."""
    token = leer_token()
    if not token:
        return None
    filas = consulta(
        "SELECT nombre, cargo, rol FROM quien_soy(:'token'::uuid);", token=token
    )
    if not filas:
        borrar_token()  # venció o la base se reinició
        return None
    return tuple(filas[0])


def iniciar_sesion(rut, clave):
    """Devuelve el estado que entrega la base: ok o fallo."""
    filas = consulta(
        "SELECT estado, coalesce(token::text, '') FROM iniciar_sesion(:'rut', :'clave');",
        rut=rut,
        clave=clave,
    )
    estado, token = filas[0]
    if estado == "ok":
        guardar_token(token)
    return estado


def cerrar_sesion():
    token = leer_token()
    if token:
        consulta("SELECT cerrar_sesion(:'token'::uuid);", token=token)
    borrar_token()


ESTILO = """
:root {
  color-scheme: light;
  --verde: #1f4d3a; --verde-2: #2c6a50; --verde-claro: #e8f1ec;
  --aromo: #f2c230; --aromo-2: #e0a91a;
  --texto: #18261f; --suave: #5a6b62; --borde: #d5ded8;
  --fondo: #f4f1e8; --tarjeta: #ffffff;
  --error: #9b2226; --error-fondo: #fcecec;
}
* { box-sizing: border-box; }
html, body { height: 100%; }
body {
  margin: 0; display: grid; place-items: center; padding: 24px;
  font: 15px/1.5 system-ui, -apple-system, "Segoe UI", Roboto, "Noto Sans", sans-serif;
  color: var(--texto);
  background:
    radial-gradient(circle at 12% 18%, rgba(242,194,48,.18) 0 140px, transparent 141px),
    radial-gradient(circle at 88% 85%, rgba(44,106,80,.10) 0 180px, transparent 181px),
    var(--fondo);
}
.tarjeta {
  width: min(100%, 880px); display: grid; grid-template-columns: 5fr 6fr;
  background: var(--tarjeta); border-radius: 20px; overflow: hidden;
  box-shadow: 0 24px 60px -20px rgba(24,38,31,.35), 0 2px 6px rgba(24,38,31,.06);
}
.marca {
  position: relative; padding: 40px 36px; color: #f3f7f4;
  background: linear-gradient(160deg, var(--verde-2), var(--verde) 70%);
  display: flex; flex-direction: column; gap: 20px; overflow: hidden;
}
.marca::after {
  content: ""; position: absolute; right: -60px; bottom: -60px; width: 220px; height: 220px;
  border-radius: 50%; background: rgba(242,194,48,.12);
}
.logo { display: flex; align-items: center; gap: 12px; }
.logo svg { flex: none; }
.logo b { display: block; font-size: 18px; letter-spacing: .01em; }
.logo span { font-size: 12px; letter-spacing: .14em; text-transform: uppercase; opacity: .75; }
.marca h2 { margin: 12px 0 0; font-size: 26px; line-height: 1.2; font-weight: 700; }
.marca p { margin: 0; opacity: .85; }
.puntos { list-style: none; margin: 4px 0 0; padding: 0; display: grid; gap: 10px; font-size: 14px; }
.puntos li { display: flex; gap: 10px; align-items: flex-start; }
.puntos li::before {
  content: ""; flex: none; width: 10px; height: 10px; margin-top: 6px; border-radius: 50%;
  background: var(--aromo); box-shadow: 0 0 0 3px rgba(242,194,48,.25);
}
.ficticio { margin-top: auto; font-size: 12px; opacity: .65; position: relative; z-index: 1; }
.panel { padding: 44px 44px 36px; display: flex; flex-direction: column; justify-content: center; }
.panel h1 { margin: 0; font-size: 26px; line-height: 1.2; }
.bajada { margin: 6px 0 24px; color: var(--suave); }
label { display: block; margin: 18px 0 6px; font-size: 13px; font-weight: 600; color: var(--suave); }
.campo { position: relative; }
input {
  width: 100%; padding: 13px 14px; font: inherit; font-size: 16px; color: var(--texto);
  background: #fbfcfb; border: 1.5px solid var(--borde); border-radius: 10px;
  transition: border-color .15s, box-shadow .15s, background .15s;
}
input::placeholder { color: #a3b0a8; }
input:focus { outline: none; border-color: var(--verde-2); background: #fff;
  box-shadow: 0 0 0 4px rgba(44,106,80,.14); }
.campo input { padding-right: 84px; }
.ver {
  position: absolute; right: 6px; top: 50%; transform: translateY(-50%);
  padding: 6px 10px; font: inherit; font-size: 13px; font-weight: 600; color: var(--verde-2);
  background: transparent; border: 0; border-radius: 6px; cursor: pointer;
}
.ver:hover { background: var(--verde-claro); }
.boton {
  width: 100%; margin-top: 26px; padding: 14px; display: flex; align-items: center; justify-content: center; gap: 10px;
  font: inherit; font-size: 16px; font-weight: 700; color: #fff; background: var(--verde);
  border: 0; border-radius: 10px; cursor: pointer; transition: background .15s, transform .05s;
}
.boton:hover { background: #173d2e; }
.boton:active { transform: translateY(1px); }
.boton[disabled] { opacity: .8; cursor: progress; }
.boton.secundario { color: var(--verde); background: #fff; border: 1.5px solid var(--borde); margin-top: 20px; }
.boton.secundario:hover { background: var(--verde-claro); border-color: var(--verde-2); }
.girando { width: 16px; height: 16px; border-radius: 50%; border: 2px solid rgba(255,255,255,.4);
  border-top-color: #fff; animation: girar .7s linear infinite; display: none; }
.boton[disabled] .girando { display: inline-block; }
@keyframes girar { to { transform: rotate(360deg); } }
.aviso {
  display: flex; gap: 10px; align-items: flex-start; margin: 0 0 4px; padding: 12px 14px;
  font-size: 14px; color: var(--error); background: var(--error-fondo);
  border: 1px solid #f3c9c9; border-radius: 10px;
}
.aviso svg { flex: none; margin-top: 2px; }
.ayuda-rut { margin: 6px 0 0; font-size: 12px; color: var(--suave); }
.persona { display: flex; align-items: center; gap: 16px; margin: 4px 0 20px; }
.avatar {
  flex: none; width: 60px; height: 60px; border-radius: 50%; display: grid; place-items: center;
  font-size: 22px; font-weight: 700; color: var(--verde); background: var(--aromo);
  box-shadow: 0 0 0 4px #fff, 0 0 0 6px var(--aromo);
}
.persona b { display: block; font-size: 20px; line-height: 1.25; }
.persona span { color: var(--suave); font-size: 14px; }
.chips { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 20px; }
.chip { padding: 5px 12px; font-size: 13px; font-weight: 600; border-radius: 999px;
  background: var(--verde-claro); color: var(--verde); }
.chip.ok::before { content: "✓ "; }
.listo { display: flex; align-items: center; gap: 8px; margin: 0 0 6px; font-size: 13px; font-weight: 700;
  letter-spacing: .08em; text-transform: uppercase; color: var(--verde-2); }
.listo::before { content: ""; width: 8px; height: 8px; border-radius: 50%; background: #2fa36b;
  box-shadow: 0 0 0 4px rgba(47,163,107,.2); }
.sugerencias { margin: 0; padding: 16px; border-radius: 12px; background: #faf7ec; border: 1px dashed #e6d9a8; }
.sugerencias p { margin: 0 0 10px; font-size: 14px; color: var(--suave); }
.pregunta { display: flex; align-items: center; justify-content: space-between; gap: 10px;
  padding: 10px 12px; margin-top: 8px; background: #fff; border: 1px solid var(--borde); border-radius: 8px; }
.pregunta span { font-weight: 600; }
.copiar { flex: none; padding: 5px 10px; font: inherit; font-size: 12px; font-weight: 600; color: var(--verde-2);
  background: var(--verde-claro); border: 0; border-radius: 6px; cursor: pointer; }
.copiar:hover { background: #d6e7dd; }
@media (max-width: 720px) {
  body { padding: 12px; }
  .tarjeta { grid-template-columns: 1fr; }
  .marca { padding: 24px; }
  .marca h2, .puntos, .ficticio { display: none; }
  .panel { padding: 28px 24px; }
}
@media (prefers-reduced-motion: reduce) { * { animation: none !important; transition: none !important; } }
"""

LOGO = """<svg width="44" height="44" viewBox="0 0 44 44" aria-hidden="true">
<circle cx="22" cy="22" r="21" fill="rgba(255,255,255,.12)"/>
<path d="M12 33 C18 27 24 22 33 12" stroke="#cfe3d7" stroke-width="2" fill="none" stroke-linecap="round"/>
<path d="M17 28 l-4 -3 M21 24 l-1 -5 M25 20 l4 1 M28 17 l-1 -5" stroke="#cfe3d7" stroke-width="1.6" stroke-linecap="round"/>
<g fill="#f2c230"><circle cx="12.5" cy="24.5" r="3.2"/><circle cx="19.5" cy="18" r="3.6"/>
<circle cx="29.5" cy="21.5" r="3.2"/><circle cx="26.5" cy="11" r="3.8"/><circle cx="34" cy="13.5" r="2.6"/></g>
</svg>"""

ICONO_ERROR = """<svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true" fill="none"
stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="10"/>
<path d="M12 7v6M12 16.5v.5"/></svg>"""

SCRIPT_LOGIN = """
const rut = document.getElementById('rut');
rut.addEventListener('input', () => {
  const limpio = rut.value.replace(/[^0-9kK]/g, '').toUpperCase().slice(0, 9);
  if (limpio.length < 2) { rut.value = limpio; return; }
  const cuerpo = limpio.slice(0, -1).replace(/\\B(?=(\\d{3})+(?!\\d))/g, '.');
  rut.value = cuerpo + '-' + limpio.slice(-1);
});
const clave = document.getElementById('clave');
const ver = document.getElementById('ver');
ver.addEventListener('click', () => {
  const oculta = clave.type === 'password';
  clave.type = oculta ? 'text' : 'password';
  ver.textContent = oculta ? 'Ocultar' : 'Mostrar';
  ver.setAttribute('aria-pressed', String(oculta));
  clave.focus();
});
document.getElementById('form').addEventListener('submit', () => {
  const b = document.getElementById('entrar');
  b.disabled = true; b.querySelector('.texto').textContent = 'Verificando…';
});
"""

SCRIPT_SESION = """
document.querySelectorAll('.copiar').forEach((b) => b.addEventListener('click', async () => {
  try { await navigator.clipboard.writeText(b.dataset.texto); b.textContent = 'Copiada'; }
  catch (e) { b.textContent = 'Selecciónala'; }
  setTimeout(() => { b.textContent = 'Copiar'; }, 1600);
}));
"""


def pagina(panel, script=""):
    return f"""<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Inicio de sesión · Los Aromos</title>
<style>{ESTILO}</style>
</head>
<body>
<main class="tarjeta">
<aside class="marca">
<div class="logo">{LOGO}<div><b>Los Aromos</b><span>Aseguradora</span></div></div>
<h2>La memoria de tu equipo</h2>
<p>Las notas del equipo las leen todos. Los sueldos tienen llave.</p>
<ul class="puntos">
<li>Cada persona ve solo su sueldo.</li>
<li>El rol Personas puede ver los de todo el equipo.</li>
<li>Tu sesión queda abierta solo en este escritorio.</li>
</ul>
<p class="ficticio">Empresa, personas y datos ficticios · Workshop La memoria de tu equipo</p>
</aside>
<section class="panel">
{panel}
</section>
</main>
{f"<script>{script}</script>" if script else ""}
</body>
</html>"""


def pagina_login(aviso=None, rut=""):
    bloque_aviso = (
        f'<p class="aviso" role="alert">{ICONO_ERROR}<span>{html.escape(aviso)}</span></p>'
        if aviso else ""
    )
    return pagina(f"""<h1>Inicia sesión</h1>
<p class="bajada">Entra con tu RUT y la clave que te entregaron en el workshop.</p>
{bloque_aviso}
<form id="form" method="post" action="/entrar" autocomplete="off">
<label for="rut">RUT</label>
<input id="rut" name="rut" value="{html.escape(rut, quote=True)}" placeholder="11.111.111-1"
  inputmode="text" maxlength="12" spellcheck="false" required {"" if rut else "autofocus"}>
<p class="ayuda-rut">Con o sin puntos y guion.</p>
<label for="clave">Clave</label>
<div class="campo">
<input id="clave" name="clave" type="password" required {"autofocus" if rut else ""}>
<button type="button" id="ver" class="ver" aria-controls="clave" aria-pressed="false">Mostrar</button>
</div>
<button type="submit" id="entrar" class="boton"><span class="girando"></span><span class="texto">Entrar</span></button>
</form>""", SCRIPT_LOGIN)


SUGERENCIAS = {
    "Personas": ["¿Cuál es mi sueldo?", "¿Cuánto gana Camila Rojas?", "Muéstrame todos los sueldos"],
}


def pagina_sesion(nombre, cargo, rol):
    iniciales = "".join(parte[0] for parte in nombre.split()[:2]).upper()
    puede = "Puede ver todos los sueldos" if rol == "Personas" else "Puede ver solo su sueldo"
    preguntas = SUGERENCIAS.get(rol, ["¿Cuál es mi sueldo?"])
    filas = "\n".join(
        f'<div class="pregunta"><span>{html.escape(p)}</span>'
        f'<button type="button" class="copiar" data-texto="{html.escape(p, quote=True)}">Copiar</button></div>'
        for p in preguntas
    )
    return pagina(f"""<p class="listo">Sesión iniciada</p>
<div class="persona"><div class="avatar" aria-hidden="true">{html.escape(iniciales)}</div>
<div><b>{html.escape(nombre)}</b><span>{html.escape(cargo)}</span></div></div>
<div class="chips"><span class="chip">Rol {html.escape(rol)}</span><span class="chip ok">{puede}</span></div>
<div class="sugerencias">
<p>Vuelve a OpenCode y pregúntale al agente, por ejemplo:</p>
{filas}
</div>
<form method="post" action="/salir">
<button type="submit" class="boton secundario">Cerrar sesión</button>
</form>""", SCRIPT_SESION)


class Pagina(BaseHTTPRequestHandler):
    server_version = "LoginAromos"

    def responder(self, contenido, estado=200):
        datos = contenido.encode("utf-8")
        self.send_response(estado)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(datos)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(datos)

    def redirigir(self, destino="/"):
        self.send_response(303)
        self.send_header("Location", destino)
        self.send_header("Content-Length", "0")
        self.end_headers()

    def origen_propio(self):
        """Rechaza formularios enviados desde otra página (otro origen)."""
        origen = self.headers.get("Origin")
        if origen is None:
            return True
        return origen in (f"http://127.0.0.1:{PUERTO}", f"http://localhost:{PUERTO}")

    def do_GET(self):
        ruta = self.path.split("?")[0]
        if ruta == "/salud":
            self.responder("ok")
            return
        if ruta != "/":
            self.responder(pagina("<h1>No existe</h1>"), 404)
            return
        try:
            sesion = sesion_actual()
        except (RuntimeError, subprocess.SubprocessError, OSError) as error:
            print(f"error consultando la sesión: {error}", flush=True)
            self.responder(pagina_login(MENSAJES["error"]), 503)
            return
        self.responder(pagina_sesion(*sesion) if sesion else pagina_login())

    def do_POST(self):
        ruta = self.path.split("?")[0]
        if not self.origen_propio():
            self.responder(pagina("<h1>Solicitud no permitida</h1>"), 403)
            return
        try:
            largo = min(max(int(self.headers.get("Content-Length") or 0), 0), 4096)
        except ValueError:
            self.responder(pagina("<h1>Solicitud no válida</h1>"), 400)
            return
        campos = parse_qs(self.rfile.read(largo).decode("utf-8", "replace"))
        try:
            if ruta == "/entrar":
                rut = campos.get("rut", [""])[0].strip()
                clave = campos.get("clave", [""])[0]
                if not rut or not clave:
                    self.responder(pagina_login(MENSAJES["incompleto"], rut), 400)
                    return
                estado = iniciar_sesion(rut, clave)
                if estado == "ok":
                    self.redirigir()
                else:
                    self.responder(pagina_login(MENSAJES.get(estado, MENSAJES["error"]), rut), 401)
            elif ruta == "/salir":
                cerrar_sesion()
                self.redirigir()
            else:
                self.responder(pagina("<h1>No existe</h1>"), 404)
        except (RuntimeError, subprocess.SubprocessError, OSError, IndexError) as error:
            print(f"error en {ruta}: {error}", flush=True)
            self.responder(pagina_login(MENSAJES["error"]), 503)


if __name__ == "__main__":
    servidor = ThreadingHTTPServer(("127.0.0.1", PUERTO), Pagina)
    print(f"Página de inicio de sesión en http://127.0.0.1:{PUERTO}/", flush=True)
    servidor.serve_forever()
