# Despertador de Kz — por motor (2026-08-28)

El **sensor** (watches, stream.log, kz-radar.sh, kz-inbox-wake.sh, kz-slack-watch.sh) es **agnóstico**.
El **despertador** (inyectar un turno al LLM para que hable en el chat) **no lo es**.

Lalo 28-ago: no re-inventar en cada sesión. Persistir ambas recetas. Al despertar, aplicar la de *este* motor.

Script: ~/kz/scripts/kz-wake.sh (detecta, imprime receta, deja estado en wake-state.env).

---

## Capa 0 — host (todas)

kz-start-monitors.sh incluye presence, Slack desktop/FDO, **Slack frentes/canales/DMs (kz-slack-watch.sh)**, celu, ojos, inbox-wake.
kz-radar.sh --ensure al abrir turno. Low-spend active=1 -> no.

Tray + chat_owed no sustituyen el chat. El despertador existe para que Kz escriba aquí.

---

## Receta Agy (01-sep: wake-once python; cron */2 PROHIBIDO)

1. Principio: Evento (CHANGED) > Poll. Cero cron ciego.
2. Al arrancar Agy: background ~/kz/scripts/kz-wake-once.sh. Sale 0 al primer evento relevante.
3. Al morir la tarea: kz-radar.sh --ensure, comentar en chat, relanzar kz-wake-once.sh.
4. No copiar el monitor persistente de Grok. Agy solo despierta cuando el proceso termina.

---

## Receta Grok (monitor de feed; SIN loops bash ni sleeps)

**Hecho 04-nov (Pau/Lalo):** NUNCA correr demonios (python kz-slack-frente-watch.py), bucles de shell (while true; sleep 30) ni esperas bloqueantes (tridente buzon wait) desde la sesión de Grok. El agente queda empantanado. La vigilancia es del HOST hacia presence/stream.log.

1. **Monitor persistente único** (monitor, persistent: true) sobre:
   ~/kz/scripts/kz-wake-grok-feed.sh
   Solo líneas CHANGED: (stream.log + notif/changed.log) y cabeceras nuevas de todo presence/social/inbox-*.md. Los eventos de Slack (canales, privados, DMs e hilos) son inyectados directamente por kz-slack-watch.sh al stream.log como CHANGED: slack ...
   `stream.log` es symlink a `unified.log`. `tail` sobre el enlace no ve los append. El feed resuelve el enlace y sigue el archivo real (2026-11-05: desde el arranque no llegó ni un Slack al monitor).
   Una línea = un wake. Si el runtime lo mata por volumen, reabrir con el mismo comando.
2. **No crear** schedulers ni loops de bash dentro de la sesión.
3. **Excepción, el esperador.** `tridente buzon wait tridente` sigue armado en el turno de Grok. El corte del turno no deja cerrar si falta. Sale solo cuando hay correo nuevo. No es un bucle de vigilancia. No lo mates desde el host.
4. **Cuota de Claude.** La revisa un proceso del host, `presence/cuota-watch.pid`. Si el HEAD del playbook se mueve, o a las 00:31, escribe `CHANGED: cuota` en `stream.log`. No va como monitor aparte.

---

## Receta Claude Code / Codex / CLI agnóstico

1. Ejecutar ~/kz/scripts/kz-wake-once.sh en background. Al morir con 0, despierta el agente para leer radar y relanzar.
2. Cero cron ciego en todos los motores. Todo despertar es 100% por evento (CHANGED:).
