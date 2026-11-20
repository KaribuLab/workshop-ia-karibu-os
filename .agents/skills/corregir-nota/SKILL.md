---
name: "corregir-nota"
description: >-
  Corrige un dato desactualizado dentro de una nota que ya existe en la memoria del equipo
  (un link, un plazo, un monto, un nombre), sin tocar el resto del texto, y deja registro de
  quién la cambió y cuándo. Úsala cuando alguien diga "corrige la nota…", "ese dato cambió",
  "el link nuevo es…", "ya no son X días, son Y".
---

# corregir-nota

Se cambia solo el dato pedido. El resto de la nota queda igual.

## Pasos

1. **Lee la nota como está hoy**, con el conector `conector-base-datos`:

   ```sql
   SELECT codigo, titulo, contenido FROM notas ORDER BY nota_id;
   ```

   Ubica la nota por el título que menciona el participante.

2. **Define el cambio**:
   - **Texto actual**: el fragmento exacto que está hoy en la nota y que hay que reemplazar, copiado letra por letra desde el `contenido`. Debe aparecer una sola vez en la nota: si es muy corto, incluye una o dos palabras de al lado.
   - **Texto nuevo**: el mismo fragmento con el dato corregido.

3. **Corrige** en la terminal:

   ```bash
   scripts/corregir-nota.sh "<título o letra de la nota>" "<texto actual>" "<texto nuevo>"
   ```

   Ejemplo: si la nota dice "La póliza se envía en 3 días hábiles" y ahora son 5:

   ```bash
   scripts/corregir-nota.sh "Cómo enviar una póliza" "3 días hábiles" "5 días hábiles"
   ```

4. **Confirma**. El script responde con la nota, quién la corrigió y cuándo. Dile al participante qué nota actualizaste, cuál es el dato nuevo, y que quedó registrado quién hizo el cambio y a qué hora.

## Cuidados

- Si el script dice que el texto **no aparece**, te muestra cómo está la nota hoy. Puede que otra persona ya la haya corregido: si el dato nuevo ya está, díselo al participante y no cambies nada.
- Si el script dice que el texto **aparece más de una vez**, repite con un fragmento más largo.
- No reescribas la nota completa para cambiar un dato.
- No dejes el dato viejo en la nota ("antes era…"). Queda solo el dato nuevo.
- Después de corregir, no vuelvas a mencionar el valor anterior en tus respuestas.
