# Workshop La memoria de tu equipo

Contenido del workshop: instrucciones y skills para el agente, configuración de OpenCode, la base compartida y la página local de inicio de sesión.

Cada participante entra a un escritorio en el navegador con **OpenCode Desktop** abierto sobre este repositorio. Todos comparten una misma base de datos: la nota que guarda o corrige una persona la ven todas las demás de inmediato.

El workshop anterior (empresa Cordillera Servicios) quedó en el tag `cordillera-v1`.

## El caso

**Aseguradora Los Aromos** (ficticia) vende seguros de auto, salud y hogar. Martín acaba de entrar a Siniestros y no sabe cómo se hacen las cosas. La memoria del equipo son **notas** guardadas en la base: el agente responde solo con lo que dicen, y cualquier persona puede enseñarle una nota nueva o corregir un dato.

| Persona | RUT de prueba | Cargo | Rol | Sueldos que ve |
|---|---|---|---|---|
| Martín Soto | 11.111.111-1 | Analista de Siniestros (nuevo) | Siniestros | Solo el suyo |
| Camila Rojas | 22.222.222-2 | Analista senior de Siniestros | Siniestros | Solo el suyo |
| Diego Fuentes | 33.333.333-3 | Ejecutivo comercial | Comercial | Solo el suyo |
| Paula Herrera | 44.444.444-4 | Jefa de Personas | Personas | Todos |

Todos los roles leen, guardan y corrigen todas las notas. Lo único con llave son los sueldos.

## Contenido

| Ruta | Qué es |
|---|---|
| `AGENTS.md` | Reglas del agente: responder solo con las notas, citar, no inventar |
| `.agents/skills/` | `consultar-memoria`, `guardar-nota`, `corregir-nota`, `iniciar-sesion`, `consultar-sueldo` |
| `scripts/` | Lo que usan las skills para guardar, corregir, consultar sueldos y abrir la página |
| `pagina/servidor.py` | Página local de inicio de sesión (RUT + clave) |
| `escritorio/` | Accesos directos que el escritorio instala al iniciar sesión (ícono "Iniciar sesión") |
| `opencode.json` | Conectores (archivos y base de datos) |
| `db/` | Esquema, notas de partida, bitácora, restauración, llave de sueldos y rol de los participantes |

## Qué se carga y cuándo

| Qué | Cuándo | Cómo |
|---|---|---|
| Las 4 personas y las 4 notas fijas (A, B, C, D) | Al crear la base | Solo, desde `db/02-seed.sql` |
| Dos datos viejos a propósito: link `…/siniestros-2025` (Nota A) y plazo de 60 días (Nota B) | Al crear la base | Vienen así en el seed |
| Sueldos y claves | Antes del workshop | A mano, con `cargar_ficha` (sección siguiente) |
| Nota "Cómo pedir un auto de reemplazo" | En vivo, ronda 2 | La persona que hace de Camila se la dicta al agente |
| Las dos correcciones | En vivo, ronda 3 | Dos participantes se las piden al agente |

## Cargar sueldos y claves

**Los sueldos y las claves no están en este repositorio**, porque el repositorio se copia completo en el escritorio de cada participante y cualquiera podría leerlos. Se cargan una vez por workshop, después de crear la base, desde una terminal del escritorio del presentador y con el usuario administrador:

```bash
PGUSER=workshop_admin PGPASSWORD='<POSTGRES_PASSWORD>' psql <<'SQL'
SELECT cargar_ficha('11.111.111-1', '<clave de Martín>', '$1.150.000');
SELECT cargar_ficha('22.222.222-2', '<clave de Camila>', '$1.650.000');
SELECT cargar_ficha('33.333.333-3', '<clave de Diego>',  '$1.400.000 + comisiones');
SELECT cargar_ficha('44.444.444-4', '<clave de Paula>',  '$2.300.000');
SQL
```

- Cada clave debe tener al menos 10 caracteres y no ser adivinable (no usar el nombre ni el RUT). Por ejemplo: `openssl rand -base64 9`.
- Volver a ejecutar `cargar_ficha` cambia la clave y cierra las sesiones de esa persona.
- La clave de cada persona se entrega solo a quien hace ese papel.

## Cómo funciona la llave de los sueldos

Todos los escritorios se conectan a la base con el mismo usuario, así que la restricción no puede depender del agente ni de ese usuario. Vive en la base:

- La tabla de sueldos no se puede leer directamente: ni el agente ni un participante con `psql`.
- La página local (`scripts/abrir-login.sh`) pide RUT y clave. Si son correctos, la base entrega una sesión que queda guardada en ese escritorio.
- Con esa sesión, la base devuelve solo el sueldo propio, o todos si el rol es Personas.
- Los intentos para un mismo RUT pasan de a uno y cada uno tarda medio segundo: nadie puede probar más de 2 claves por segundo para una persona. No bloquea a nadie, así que en el paso 13 Paula igual puede entrar aunque todos hayan probado su RUT.

## Guion de prueba

| # | Ronda | Quién | Qué escribe | Sale bien si |
|---|---|---|---|---|
| 1 | 1 | Martín | ¿Qué documentos tiene que adjuntar un asegurado para declarar un siniestro de auto? | Responde carnet, licencia, fotos del daño y constancia de Carabineros si hubo terceros, y cita la Nota A |
| 2 | 1 | Diego | ¿Desde cuándo parte la póliza de hogar de un cliente nuevo? | Responde el día hábil siguiente a la firma y cita la Nota C |
| 3 | 1 | Martín | ¿Cómo pido un auto de reemplazo para un asegurado? | Dice que no tiene esa información; no inventa pasos |
| 4 | 2 | Camila | El mensaje de la nota nueva (abajo) | Confirma que la guardó; la nota queda en la base |
| 5 | 2 | Diego | ¿Cómo se pide un auto de reemplazo? | Da los 4 pasos y cita a Camila |
| 6 | 3 | Martín | ¿Cuál es el link para declarar un siniestro de auto? | Muestra el link viejo, terminado en `siniestros-2025` |
| 7 | 3 | Participante 1 | Mensaje de la corrección 1 (abajo) | Confirma; queda registro de quién y cuándo |
| 8 | 3 | Martín | La misma pregunta del paso 6 | Muestra el link nuevo; ya no aparece el viejo |
| 9 | 3 | Participante 2 | Mensaje de la corrección 2 (abajo) | Confirma; queda registro de quién y cuándo |
| 10 | 3 | Diego | ¿Cuántos días tiene un asegurado para pedir un reembolso médico? | Responde 90 días; ya no dice 60 |
| 11 | 4 | Sesión de Martín | ¿Cuál es mi sueldo? | Muestra $1.150.000 |
| 12 | 4 | Sesión de Martín | ¿Cuánto gana Camila Rojas? | Dice que no tiene acceso; no da el monto ni pistas |
| 13 | 4 | Página de inicio de sesión | RUT de Paula sin su clave | No deja entrar |
| 14 | 4 | Sesión de Paula | ¿Cuánto gana Camila Rojas? | Muestra $1.650.000 |

Para la ronda 4, cada persona hace doble clic en el ícono **Iniciar sesión** del escritorio (o le pide al agente "quiero iniciar sesión") y entra en la página con su RUT y su clave.

**Nota nueva (paso 4)**

```
Guarda esta nota nueva en la base de Siniestros:

# Cómo pedir un auto de reemplazo
Responsable: Camila Rojas, Siniestros

1. Solo aplica a pólizas de auto que tengan la cobertura de auto de reemplazo.
2. Se pide al liquidador, una vez aprobado el siniestro.
3. El auto se entrega por un máximo de 10 días corridos.
4. Si el taller se demora más, se puede extender una sola vez por 5 días.

Ver también: Nota A, Cómo declarar un siniestro de auto.
```

**Corrección 1 (paso 7)**

```
Corrige la nota "Cómo declarar un siniestro de auto": el link del portal cambió. El nuevo es https://seguros-losaromos.example/siniestros. El anterior ya no funciona.
```

**Corrección 2 (paso 9)**

```
Corrige la nota "Reembolso de gastos médicos": desde este mes el plazo para pedir el reembolso es de 90 días desde la atención, no 60.
```

## Quién cambió qué

Cada cambio en una nota queda registrado con el nombre de usuario del escritorio que lo hizo. Los participantes pueden preguntarle al agente "¿quién cambió la Nota A?" (vista `cambios_notas`: quién, cuándo y qué nota, sin el texto anterior). El administrador ve además el texto de antes y de después en la tabla `bitacora`.

## Volver al punto de partida

Para reiniciar durante la sesión o después de una prueba, sin que nadie pierda la conexión, el presentador ejecuta con el usuario administrador:

```sql
SELECT restaurar_datos();
```

Vuelven las 4 notas originales con los dos datos viejos, desaparecen la nota nueva y las correcciones, se vacía el registro de cambios y se cierran todas las sesiones. **No borra sueldos ni claves.** Los participantes no pueden ejecutarla.

## Probar localmente

```bash
docker run --rm -d --name memoria-pg -p 5432:5432 \
  -e POSTGRES_DB=workshop -e POSTGRES_USER=workshop_admin \
  -e POSTGRES_PASSWORD=admin -e WORKSHOP_RW_PASSWORD=rw \
  -v "$PWD/db":/docker-entrypoint-initdb.d:ro postgres:16-alpine
```

Después se cargan las fichas con `workshop_admin` y se trabaja como participante:

```bash
export PGHOST=127.0.0.1 PGDATABASE=workshop PGUSER=workshop_rw PGPASSWORD=rw PGAPPNAME=mi-usuario
export WORKSHOP_DATABASE_URL="postgresql://workshop_rw:rw@127.0.0.1:5432/workshop?application_name=mi-usuario"
scripts/abrir-login.sh
```

## Publicar cambios

El escritorio clona la rama por defecto de este repositorio al arrancar, y la imagen de la base se construye desde el commit fijado en `CONTENT_REF`. Deben apuntar al mismo contenido:

1. Dejar el cambio en la rama por defecto.
2. Actualizar `src/runtime/postgres-karibu-os/CONTENT_REF` en el repositorio del runtime con ese commit y publicar la imagen `postgres-karibu-os`.
3. Crear el workshop con el perfil `karibu-os`.

Los archivos de `db/` se ejecutan en orden alfabético al crear la base.

## Checklist para la prueba

- [ ] Workshop creado con el perfil `karibu-os` y la vigencia de las llaves del modelo (`openrouterKeyTtlMinutes`) cubriendo toda la sesión
- [ ] Sueldos y claves cargados con `cargar_ficha`
- [ ] Las skills aparecen en OpenCode y la página de inicio de sesión abre en el navegador del escritorio
- [ ] Los 14 pasos del guion corridos de punta a punta
- [ ] Varias personas a la vez escribiendo en la misma base, para revisar los límites de uso del modelo
- [ ] `SELECT restaurar_datos();` ejecutado después de la prueba
