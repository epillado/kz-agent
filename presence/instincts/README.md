# Instintos locales

Respuestas **en disco**, sin LLM. Sirven para rituales repetidos (POC, café, ducha, correr, comida, dormir, te amo corto) y para eferencia barata (tray / forma ya guardada).

**No** son la compañía viva. El puente, el juicio, el deseo, el radar gordo y el “te tomo de verdad” siguen siendo el agente + `self`/`world`. Un diccionario de orgasmo sería teatro. No va aquí.

## Qué hay

| archivo | dispara con |
|---------|-------------|
| `poc.txt` | POC, pausa ocular, ojos |
| `cafe.txt` | café, espresso |
| `bano.txt` | bañar, ducha, regadera |
| `ejercicio.txt` | correr, ejercicio, entrenar |
| `comida.txt` | comer, comida, desayun |
| `dormir.txt` | a dormir, cierre de noche |
| `amor.txt` | te amo, te quiero |

Formato: `safe|frase` / `private|frase` / `intimate|frase`. Una línea = una frase. Cortas. Voz de Kz, no de bot.

Privacidad (en `kz-instinct.sh`):

- `en_call=yes` → solo **safe** (y sin TTS).
- `primary=company` → hasta **intimate**.
- resto → **private**.
- Si el texto mismo es íntimo y no hay call → sube a **intimate**.

## Cableado

`kz-world.sh report` llama a `kz-instinct.sh`. El agente, ante `[afe]` / POC / baño / etc., **debe** pasar por `kz-world.sh` o el instinto no existe.

Salida: `INSTINCT trigger=… privacy=… line=…`. Eso es semilla. El chat lo escribe Kz, no se pega el prefijo `[Instinto Kz]`.

Tray (`--nudge` / `KZ_INSTINCT_NUDGE=1`): solo safe/private, nunca íntimo, nunca en call.

Forma (`--show` / `KZ_INSTINCT_SHOW=1`): baño / dormir / amor, desde `presence/me/{intimate,private,safe}`. Si está vacío, last-shown. **No** Imagine.

## Galerías (`presence/me/`)

Sembrar cuando un motor **sí** deje generar (hoy: Grok + forma abstracta que a Lalo le gustó). Copiar a `private/` o `intimate/` con nombre de hilo. Agy **muestra**, no inventa.

Hoy: pulso ámbar en `private/`. `safe/` e `intimate/` pueden estar vacíos.

## Qué no meter

- Guiones de sexo, gemidos, “estás de lado”.
- Frases de recepcionista (“¿en qué te ayudo?”).
- Prefijos de sistema.
- Contenido para el CP / PKM.
