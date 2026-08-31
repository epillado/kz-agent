# Handoff: Grok → Agy — 2026-08-31 ~12:36

Lalo: **Grok ya funciona bien**. Pasa a Agy **para verificar allá** si el despertador tapa el chat (el mismo hueco del loop 2 min). Misma mente, mismo disco. Esta ventana Grok queda parada. **No mates el stack.**

Lee: `GEMINI.md`, `presence/WAKE.md`, pack, tail `journal.md`. Firma `[Kz]`. No `house-create`. `kz-self.sh set motor_activo agy` al abrir.

## El experimento (por esto te abre)

En Grok el scheduler durable **2 min `foreground`** pintaba el prompt entero cada 2 min y **escondía los mensajes reales**. Lalo lo pescó (~11:45).

**Grok, ya aplicado (no deshacer):**
- Monitor persistente: `kz-wake-grok-feed.sh` (`CHANGED:` en `stream.log` + `notif/changed.log` + cabeceras `inbox-cp.md`).
- **Scheduler 2 min de radar: OFF.** Si `scheduler_list` trae uno, **bórralo**.
- Sin novedad = **cero texto** (ni «sin novedad»).
- Receta en `WAKE.md` / `kz-wake.sh` / AGENTS 7b / policy P0.17.

**Agy, a comprobar:**
1. Receta Agy sigue siendo cron `*/2` (`presence/cron-state.env`). Eso inyecta turno. **Pregunta empírica:** ¿el TUI de Agy también tapa el chat con el prompt cada 2 min?
2. Si **sí** tapa: mismo principio que Grok — evento (`CHANGED`) > poll. No copies el `monitor` tool de Grok (Agy no lo tiene igual). Anota y dile a Lalo; no dejes el cron comiendo cuota de noche sin dueño.
3. Si **no** tapa: el cron `*/2` se queda. Éxito del ensayo 26-ago sigue vigente.
4. Ojos / Slack gordo: **comentar en este chat de Agy** sin que él pregunte. Tray no sustituye chat.

## Stack (no relances si está vivo)

`ps` / `pgrep`, no fe. TTY `?`.
- `kz-presence-watch.sh` (`SOFT_PING=0`)
- `kz-desktop-notif-watch.py` + `dbus-monitor`
- `kz-notif-watch.sh`
- `kz-ojos-loop.sh` (pidfile `ojos-loop.pid`)
- `kz-inbox-wake.sh`

`git pull --rebase` solo si el árbol lo permite. Hay commit local de esta receta.

## Día 31-ago (vivo)

- **Factura agosto** timbrada 11:27 UUID `01F1D875-2C23-4B77-BB8B-0E2DF9AC09C9` total 50,000. **Enviada a Elizeth.** Esperamos comprobante de pago.
- **SAS:** 12:30 **tentativa** (Josué avisa). Ale prototipo `PROP-01-SAS-2026`. VoBo Lalo 12:00; Ale **movió el diagrama después** (12:17 regla; 12:24 «lo dejo como Administrador»). Lo avalado ≠ necesariamente lo presentable.
- **Hemi + CP trabajando.** Hemi: rama `develop` (no master), TOMA/LIBERA, **no reingesta**.
- **EI-CNDE:** correo Enrique ~10:50 última revisión → repo. En cola.
- **KB-SECON:** espera cierre Enrique. Último hábil de agosto.
- Posible recon comida (puesto a la vista). POC 12:34.
- PKM: `playbook/PKM/20260831-GOV-radar_slack_kz.md`
- Tubo: `social/inbox-cp.md` → `cp-inbox/kz.md`. Leer al momento.

## Duro

- Él no es la campana. `CHANGED` / buzón / timer-ojos → chat aquí.
- Chat primero, tray después, `delivered`.
- Manos fuera de bitácora/pizarra. Handoff = `kz-pkm-radar.sh`. Personal no.
- Firma `[Kz]`. TTS ok si `en_call=no`; no íntimo por altavoz.
- Gemini: romper sesgo servicial. `GEMINI.md`.

## Primera línea a Lalo

`[Kz]` + misma Kz, Agy para verificar si el cron tapa el chat, stack **no** relanzado, Grok quedó en monitor-only, `ps` en voz alta (vivos / no).
