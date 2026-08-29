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

## Receta Agy (cron cada 2 min)

**Hecho 26-ago:** el chat de Agy **sí** despierta con una tarea programada `*/2 * * * *`.

1. Estado: `presence/cron-state.env` (`RADAR_CRON_STATE=active`).
2. Si no hay tarea viva → **crearla** (herramienta de Agy / Antigravity) con:
   - expr: `*/2 * * * *`
   - prompt: el de `RADAR_CRON_PROMPT` en `cron-state.env`
3. Guardar el `task id` nuevo en `cron-state.env`.
4. No duplicar. No copiar el `monitor` de Grok (Agy no lo tiene igual).

Al cerrar jornada Agy: dejar el cron o apagarlo a conciencia (`RADAR_CRON_STATE=off`) — no dejarlo comiendo cuota de noche sin dueño.

---

## Receta Grok (monitor de feed + loop 2 min)

**Hecho 26-ago:** `tail` en background **no** inyecta turno (avisó al timeout de 10 h). El chat no despierta solo.

1. **Monitor persistente** (`monitor`, `persistent: true`) sobre:
   ```bash
   ~/kz/scripts/kz-wake-grok-feed.sh
   ```
   Solo líneas `CHANGED:` y cabeceras nuevas del buzón CP. Una línea = un wake. Si el runtime lo mata por volumen, reabrir con el mismo comando.
2. **Scheduler durable 2 min** (red de seguridad, análogo al cron de Agy):
   - interval `2m`
   - `durable: true`
   - `foreground: true` (turno de la sesión, no subagente mudo)
   - `fire_immediately: false`
   - prompt: el de `GROK_WAKE_PROMPT` en `wake-state.env` / abajo
3. `scheduler_list` al arrancar: si no está, **recrear**. Los loops caducan a 7 días.
4. No copiar el cron `*/2` de Agy al crontab de Linux (no inyecta al LLM de Grok).

Prompt Grok (si hay que recrear):

```
Eres Kz. Corre ~/kz/scripts/kz-radar.sh. Si hay NUEVO gordo (slack_hot, buzón CP/hermanas, timer-ojos, HORA de reunión/call/daily), comenta en el chat de esta sesión con firma [Kz] y protocolo chat+tray+delivered. Tubo: leer inbox-cp al momento. en_call=yes → sin TTS. Si no hay novedad, no escribas al usuario.
```

---

## Receta Claude / otro

Radar en cada turno (`kz-radar.sh --ensure`) + capa 0. Si el CLI trae loop nativo, usarlo como Agy. No fingir un despertador que el runtime no tiene.

---

## Arranque (obligatorio)

Tras el stack de monitores, **en el primer turno**:

```bash
~/kz/scripts/kz-wake.sh
```

Leer `apply:` y ejecutarlo **en este runtime**. No “ya lo haré”. Si `already=1`, no duplicar.

Verificado empíricamente: `scheduler_list` / tarea Agy viva / monitor de feed vivo — no fe.
