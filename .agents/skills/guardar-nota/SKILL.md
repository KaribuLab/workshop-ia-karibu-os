---
name: "guardar-nota"
description: >-
  Guarda una nota nueva en la memoria del equipo (base compartida) para que todas las
  personas y áreas la puedan consultar. Úsala cuando alguien pida "guarda esta nota",
  "anota esto", "enséñale esto al equipo" y entregue el texto. Guarda el texto tal cual,
  sin resumirlo ni mejorarlo. Para cambiar un dato de una nota que ya existe usa corregir-nota.
---

# guardar-nota

Quien te entrega la nota es quien sabe del tema. Tu trabajo es guardarla exacta.

## Pasos

1. **Saca tres datos del mensaje**:
   - **Título**: la línea que empieza con `# `, sin el `# `.
   - **Responsable**: el nombre que sigue a `Responsable:` (solo el nombre, sin el área).
   - **Área**: `Siniestros`, `Comercial` o `Personas`. Es la que nombra el mensaje ("en la base de Siniestros") o la que acompaña al responsable.

   Si falta alguno, pregúntalo antes de guardar. No lo inventes.

2. **Guarda la nota** en la terminal. El contenido es el texto completo de la nota, desde la línea del título hasta el final, copiado tal cual:

   ```bash
   scripts/guardar-nota.sh "<título>" "<área>" "<responsable>" - <<'NOTA'
   # <título>
   Responsable: <responsable>, <área>

   <resto del texto, sin cambios>
   NOTA
   ```

   La instrucción del participante ("Guarda esta nota nueva…") no es parte del contenido.

3. **Confirma**. El script responde con la letra de la nota, quién la guardó y cuándo. Dile al participante, por ejemplo:
   "Guardé la Nota E · Cómo pedir un auto de reemplazo (responsable: Camila Rojas, Siniestros). Desde ahora cualquier persona del equipo puede consultarla."

## Cuidados

- No corrijas ortografía, no resumas, no reordenes ni agregues pasos.
- La letra de la nota la asigna la base. No la elijas tú.
- Si el script dice **"La nota ya estaba guardada, sin cambios"**, otra persona la guardó antes: díselo al participante, no es un error.
- Si el script dice **"Nota reemplazada"**, ya existía una nota con ese título y quedó con el texto nuevo: avísalo.
- Si el script falla, muestra el mensaje en simple y no intentes guardar la nota de otra forma.
