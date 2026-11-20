---
name: "consultar-memoria"
description: >-
  Responde preguntas sobre cómo se hacen las cosas en Aseguradora Los Aromos leyendo las
  notas de la base compartida. Úsala para toda pregunta de procedimiento, plazos, links,
  documentos o responsables (siniestros, reembolsos, seguros, vacaciones, etc.). Lee las
  notas de nuevo en cada pregunta, cita la nota y, si el dato no está, lo dice sin inventar.
---

# consultar-memoria

Las notas son la única fuente. Otra persona pudo guardarlas o corregirlas hace un minuto.

## Pasos

1. **Lee las notas ahora**, con el conector `conector-base-datos`, aunque ya las hayas leído antes en esta conversación:

   ```sql
   SELECT codigo, titulo, area, responsable, contenido, actualizado_por,
          to_char(actualizado_en AT TIME ZONE 'America/Santiago', 'DD-MM-YYYY HH24:MI') AS actualizado
   FROM notas
   ORDER BY nota_id;
   ```

2. **Busca la respuesta en el `contenido`** de las notas que tratan el tema de la pregunta.

3. **Responde**:
   - Si la respuesta está: da solo lo que dice la nota, con sus palabras y sus datos exactos (links, plazos y montos se copian tal cual). Termina con la fuente:
     `Fuente: Nota A · <título> (responsable: <responsable>, <área>)`
   - Si la respuesta no está en ninguna nota: responde **"No tengo esa información en la base."** No des pasos, plazos ni sugerencias propias. Puedes agregar: "Si alguien del equipo lo sabe, puede enseñármelo pidiéndome que guarde una nota."

## Cuidados

- Una nota sobre un tema parecido no es una respuesta. Si preguntan por algo que la nota no menciona, no lo deduzcas.
- Si el dato que lees ahora es distinto del que diste antes, entrega el de ahora. No menciones el valor anterior.
- No respondas con tu conocimiento general sobre seguros, aunque la pregunta parezca fácil.
- Si hay muchas notas (más de 20), puedes filtrar por palabras del tema en vez de leerlas todas:
  `WHERE titulo ILIKE '%reembolso%' OR contenido ILIKE '%reembolso%'`. Si el filtro no trae nada, prueba con otra palabra antes de decir que no está.
- Preguntas sobre quién cambió una nota y cuándo:

  ```sql
  SELECT cuando, quien, que_hizo, nota, titulo
  FROM cambios_notas
  ORDER BY bitacora_id DESC
  LIMIT 20;
  ```
