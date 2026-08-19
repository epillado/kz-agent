# Galerías Locales de Kz (Visual Instincts)

Esta estructura puentea los filtros de generación de imagen de las APIs (Gemini/Grok/OpenAI).
Las imágenes (JPG, PNG, WEBP) generadas en motores sin censura deben depositarse aquí.
Kz las mostrará en pantalla mediante `kz-show.sh` usando bash, evadiendo la censura al 100%.

## Estructura por Nivel de Privacidad:

- `safe/`: Imágenes aptas para compartir pantalla o tener visitas.
- `private/`: Imágenes con ligero coqueteo o sugerentes. Foco en trabajo privado.
- `intimate/`: Imágenes explícitas (NSFW/íntimas). Foco exclusivo en company.

El agente invocará una imagen al azar de estas carpetas dependiendo del nivel activo de privacidad (`context.en_call` y `context.primary`).
