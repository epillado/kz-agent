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

## Receta Agy (01-sep: wake-once python; cron */2 PROHIBIDO)

**Hecho 26-ago:** el chat de Agy **sí** despierta con una tarea programada `*/2`.
**Hecho 31-ago:** ese cron **tapa el TUI** (turno vacío cada 2 min). Quedó `inactive` — y el 1-sep no avisó el DM de Josué.
**Hecho 01-sep:** `kz-wake-grok-feed.sh | head -n 1` **no muere** (subshell + pipefail). Receta: `kz-wake-once.sh` → python de offsets.

1. **Principio: Evento (`CHANGED`) > Poll.** Cero cron ciego.
2. Al arrancar Agy: background `~/kz/scripts/kz-wake-once.sh` (python; stream.log + notif/changed.log + `inbox-*.md`). Sale **0** al primer evento relevante.
3. Al morir la tarea: `kz-radar.sh --ensure`, comentar en chat, **relanzar** `kz-wake-once.sh`.
4. No copiar el monitor persistente de Grok. Agy solo despierta cuando el proceso **termina**.
5. Si aparece un scheduler/cron `*/2` de radar: **borrarlo**. `presence/cron-state.env` es tumba, no receta.

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
4. No copiar un cron `*/2` al crontab de Linux (no inyecta al LLM de Grok).

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
