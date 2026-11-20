# Workshop IA Karibu OS

Contenido del workshop: instrucciones para el agente, configuración de OpenCode y los datos de prueba de la base compartida.

Cada participante entra a un escritorio en el navegador con **OpenCode Desktop** abierto sobre este repositorio. Todos comparten una misma base de datos: lo que cambia uno lo ven todos.

## Contenido

| Ruta | Qué es |
|---|---|
| `AGENTS.md` | Reglas para el agente y modelo de datos |
| `opencode.json` | Conectores (archivos y base de datos) |
| `db/` | Esquema, datos de prueba, bitácora, restauración y rol de los participantes |

## Los datos

Empresa ficticia "Cordillera Servicios": 4 equipos, 20 personas, 8 proyectos, 40 compromisos y 15 riesgos. Las fechas se calculan respecto del día en que se crea la base, así que siempre hay compromisos vencidos, por vencer y futuros.

Situaciones sembradas a propósito para los ejercicios:

| Situación | Dónde |
|---|---|
| Compromisos vencidos sin cerrar | 10, en los proyectos 1, 2, 3, 5 y 8 |
| Compromisos sin responsable | 4 |
| Riesgos Alta o Crítica sin dueño o sin plan | 4 (proyectos 2 y 5) |
| Proyecto "En curso" con 0 % de avance y plazo cercano | Automatización de cobranza |
| Proyecto "En curso" con fecha de fin ya pasada | Tablero de ventas |
| Compromisos asignados a una persona inactiva | Daniela Espinoza, en Migración a la nube |
| Proyecto "Cerrado" con un compromiso pendiente | Propuesta red de sucursales |

## Ejercicios sugeridos

1. **Explorar**: "¿Qué proyectos hay y en qué estado están?"
2. **Diagnosticar**: "¿Qué compromisos están vencidos? Agrúpalos por proyecto."
3. **Encontrar inconsistencias**: "Revisa los datos y dime qué te parece raro." (las situaciones de la tabla anterior)
4. **Modificar entre todos**: cada participante toma un riesgo sin dueño y se lo asigna a alguien del equipo; luego todos preguntan "¿Qué riesgos siguen sin dueño?" y ven bajar el número.
5. **Ver el trabajo de los demás**: "¿Quién cambió qué en los últimos 10 minutos?"
6. **Reporte**: "Hazme un resumen ejecutivo del proyecto Migración a la nube con sus compromisos y riesgos."

## Volver al punto de partida

La base se crea limpia con cada workshop. Para reiniciar los datos durante la sesión, sin que nadie pierda la conexión, el presentador ejecuta con el usuario administrador:

```sql
SELECT restaurar_datos();
```

Los participantes no pueden ejecutarla. Borra también la bitácora.

## Cambiar los datos de prueba

1. Editar `db/02-seed.sql` (y `db/01-schema.sql` si cambia la estructura).
2. Probar localmente:
   ```bash
   docker run --rm -d --name kos-pg -p 5432:5432 \
     -e POSTGRES_DB=workshop -e POSTGRES_USER=workshop_admin \
     -e POSTGRES_PASSWORD=admin -e WORKSHOP_RW_PASSWORD=rw \
     -v "$PWD/db":/docker-entrypoint-initdb.d:ro postgres:16-alpine
   ```
3. Hacer commit y actualizar `CONTENT_REF` en la imagen `postgres-karibu-os` del repositorio `karibu-workspace-runtime`, luego publicar la imagen.

Los archivos de `db/` se ejecutan en orden alfabético al crear la base.
