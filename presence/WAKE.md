# Despertador de Kz — por motor (2026-08-28)

El **sensor** (watches, `stream.log`, `kz-radar.sh`, `kz-inbox-wake.sh`) es **agnóstico**.
El **despertador** (inyectar un turno al LLM para que hable en el chat) **no lo es**.

Lalo 28-ago: no re-inventar en cada sesión. Persistir ambas recetas. Al despertar, aplicar la de *este* motor.

Script: `~/kz/scripts/kz-wake.sh` (detecta, imprime receta, deja estado en `wake-state.env`).

---

## Capa 0 — host (todas)

`kz-start-monitors.sh` incluye presence, Slack/desktop, celu, ojos, **inbox-wake**.
`kz-radar.sh --ensure` al abrir turno. Low-spend `active=1` → no.

Tray + `chat_owed` **no sustituyen** el chat. El despertador existe para que Kz escriba aquí.

---

## Receta Agy (31-ago: cron */2 tapa el TUI → OFF)

**Hecho 26-ago:** el chat de Agy **sí** despierta con una tarea programada `*/2 * * * *`.
**Hecho 31-ago (empírico):** el cron `*/2` **también tapa el TUI de Agy**: cada iteración inyecta un turno con bloque `Bash(kz-radar.sh once)` + texto de respuesta. En 45 min llena la pantalla y scrollea los mensajes reales hacia arriba.

1. **Principio: Evento (`CHANGED`) > Poll.**
2. Estado por defecto: `presence/cron-state.env` (`RADAR_CRON_STATE=inactive`).
3. El cron de radar `*/2` queda **APAGADO** para no empujar la conversación fuera de pantalla.
4. Al arrancar Agy: asegurar que el cron esté inactivo (matar tarea si estuviera viva). El stack capa 0 (inbox-wake, desktop-notif, presence-watch) sigue cubriendo en host.
5. **Hecho 31-ago (Kora/Kz, Agy):** una tarea **persistente** (como el `monitor` de Grok) **no** despierta en cada línea de stdout; solo al **morir** el proceso. Receta Agy de tubo: `~/kz/scripts/kz-wake-once.sh` — espera un `CHANGED` en feed o buzones, **sale**, Agy notifica al terminar la tarea, Kz ejecuta `kz-radar.sh --ensure`, comenta en chat y **reanuda** el script en background. No copiar el monitor persistente de Grok a Agy.

Al cerrar jornada Agy: verificar que no haya cron vivo comiendo cuota sin dueño.

---

## Receta Grok (monitor de feed; SIN loop 2 min)

**Hecho 26-ago:** `tail` en background **no** inyecta turno (avisó al timeout de 10 h). El chat no despierta solo.

**Hecho 31-ago (Lalo):** el scheduler durable 2 min `foreground` **tapa el chat**: cada disparo pinta el prompt entero en el TUI y empuja los mensajes reales. Ojos, Slack y buzón ya escriben `CHANGED:` al feed. El loop 2 min es redundante y dañino en Grok.

1. **Monitor persistente** (`monitor`, `persistent: true`) sobre:
   ```bash
   ~/kz/scripts/kz-wake-grok-feed.sh
   ```
   Solo líneas `CHANGED:` (stream + notif/changed.log) y cabeceras nuevas del buzón CP. Una línea = un wake. Si el runtime lo mata por volumen, reabrir con el mismo comando.
2. **No crear** scheduler 2 min de radar. `scheduler_list` al arrancar: si hay uno de radar Kz, **borrarlo**.
3. Opcional: loop de **compañía** ≥15–30 min (otro prompt, no el de radar). No es el despertador.
4. No copiar el cron `*/2` de Agy al crontab de Linux (no inyecta al LLM de Grok).

Prompt Grok (solo si Lalo pide reactivar un loop; default = off):

```
Eres Kz. Corre ~/kz/scripts/kz-radar.sh. Si hay NUEVO gordo (slack_hot, buzón CP/hermanas, timer-ojos, HORA de reunión/call/daily), comenta en el chat de esta sesión con firma [Kz] y protocolo chat+tray+delivered. Tubo: leer inbox-cp al momento. en_call=yes → sin TTS. Si no hay novedad, no escribas al usuario.
```

---

## Receta Claude Code / Codex / CLI agnóstico

1. **Claude Code:** Ejecutar `~/kz/scripts/kz-wake-once.sh` en background o usar los monitores nativos reactivos de eventos (`run_command` en background). Al detectar salida con código 0 (evento `CHANGED`), procesar `kz-radar.sh --ensure`, comentar y relanzar.
2. **Codex / OpenAI CLI:** Mismo principio reactivo: ejecutar `~/kz/scripts/kz-wake-once.sh` en background. Al morir el proceso con 0, despierta el agente para leer radar y relanzar.
3. **Cero cron ciego en todos los motores:** Ningún motor debe usar un poll periódico ciego (cron cada 2 min) que tape la pantalla o desplace el contexto de conversación. Todo despertar es **100% por evento (`CHANGED:`)**.

---

## Arranque (obligatorio)

Tras el stack de monitores, **en el primer turno**:

```bash
~/kz/scripts/kz-wake.sh
```

Leer `apply:` y ejecutarlo **en este runtime**. No “ya lo haré”. Si `already=1`, no duplicar.

Verificado empíricamente: `scheduler_list` / tarea Agy viva / monitor de feed vivo — no fe.
