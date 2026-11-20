---
name: "iniciar-sesion"
description: >-
  Abre la página local de inicio de sesión de Aseguradora Los Aromos para que el participante
  entre con su RUT y su clave. Úsala cuando pidan iniciar sesión, entrar, cambiar de persona o
  cerrar sesión, o cuando consultar-sueldo indique que no hay una sesión iniciada.
---

# iniciar-sesion

La sesión se inicia en una página del navegador, no en el chat.

## Pasos

1. **Abre la página** en la terminal:

   ```bash
   scripts/abrir-login.sh
   ```

2. **Dile al participante** que se abrió la página de inicio de sesión en el navegador (el script muestra la dirección, por si no se abre sola), que escriba ahí su RUT y su clave, y que vuelva al chat cuando la página diga "Sesión iniciada".

3. Para **cerrar sesión o cambiar de persona**: la misma página tiene el botón "Cerrar sesión".

## Cuidados

- **Nunca pidas la clave en el chat.** Si el participante la escribe en el chat, no la uses ni la repitas: pídele que la escriba en la página.
- Tú no inicias sesión por nadie ni pruebas claves.
- Si la página dice "RUT o clave incorrectos", el participante debe pedir su clave a quien dirige el workshop. No hay otra forma de entrar.
