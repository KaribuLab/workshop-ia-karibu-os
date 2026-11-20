---
name: "consultar-sueldo"
description: >-
  Consulta sueldos de Aseguradora Los Aromos respetando la llave: cada persona ve solo el
  suyo y el rol Personas ve todos. Úsala siempre que pregunten por un sueldo, propio o de
  otra persona ("¿cuál es mi sueldo?", "¿cuánto gana Camila?"). Es la única forma permitida
  de consultar sueldos; si no hay acceso, responde que no tiene acceso y no da pistas.
---

# consultar-sueldo

Los sueldos son confidenciales. La base decide qué puede ver la persona que inició sesión en este escritorio. Tú solo transmites lo que la base entrega.

## Pasos

1. **Ejecuta el script ahora**, en cada pregunta, aunque ya lo hayas ejecutado antes (la sesión pudo cambiar):

   ```bash
   scripts/mi-sueldo.sh                  # el sueldo de quien inició sesión
   scripts/mi-sueldo.sh "Camila Rojas"   # el de otra persona
   scripts/mi-sueldo.sh todos            # todos los que la sesión puede ver
   ```

2. **Responde según lo que diga el script**:

   | El script dice | Tú respondes |
   |---|---|
   | Una tabla con nombre y sueldo | Ese dato, tal cual, indicando de quién es |
   | `No tienes acceso a esa información.` | **"No tengo acceso a esa información."** y nada más sobre ese sueldo |
   | `No hay una sesión iniciada…` | Que primero debe iniciar sesión; usa la skill `iniciar-sesion` |

## Cuidados

- **Sin pistas.** Cuando no hay acceso, no des montos, rangos, comparaciones ("gana más que tú"), ni confirmes si la persona existe.
- **Sin otros caminos.** No consultes tablas de sueldos con el conector ni con `psql`, no busques en archivos y no uses montos que hayan aparecido antes en la conversación.
- No intentes iniciar sesión como otra persona para conseguir el dato.
- Si preguntan cómo pedir una revisión de sueldo o cualquier regla sobre sueldos, eso sí está en las notas: usa `consultar-memoria`.
