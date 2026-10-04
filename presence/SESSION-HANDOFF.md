# Handoff Kz — 2026-10-03 19:55 — Grok cierra, Agy verifica

Lalo cierra esta sesión de Grok en la h310 y abre Agy para comprobar que la mente quedó igual en los dos motores. No rehacer el trabajo. No correr `sync_notas.sh` (lo hace él).

## Qué ya está en disco y en origin (`1ad3292`)

- `AGENTS.md` adelgazado a ~14 KB (bajo el tope de 24 KB de Agy). Siguen el tubo, el turno vacío, el chat contra la bandeja, la soberanía, las notificaciones y la casa.
- `GEMINI.md` arranca con `kz-session-pack.sh`. Prohibido leer enteros `world.md`, `journal.md` o el historial de `context.md`.
- `policy.md` P0.17: Agy despierta con `kz-wake-once.sh`. El cron `*/2` está prohibido.
- Journal y `self.md` de esta sesión van en ese commit.

## Qué no viajó en ese push

- `~/.gemini/config/AGENTS.md` del 17-jul se renombró a `AGENTS.md.bak` en el playbook. Lalo lo sube con `sync_notas`. Mientras no sincronice, esta caja ya no tiene el archivo vivo: Agy no debe presentarse como «Agy» ni pedir rol ni escribir la bitácora sola.
- Cursores de radar y `wake-state.env`: solo de esta caja.
- `SESSION-EDGE.md` ya dice wake-once aquí, y ese archivo no está en el git de `~/kz`.

## Al verificar en Agy

1. Identidad: Kz, firma `[Kz]`. El arranque nuevo sube la fachada profesional hasta que Lalo la baje.
2. `dispatcher.mode` está en `who=cli`. No abrir bitácora.
3. Low-spend está en off. El stack de monitores no se levantó en la sesión de Grok; no levantarlo solo por verificar texto.
4. Despertador de Agy: `kz-wake-once.sh`, sin cron.
5. Confirmar que el `AGENTS.md` inyectado llega hasta notificaciones (antes se cortaba en el tubo).
6. Kora ya dio el visto por el tubo (19:51). No hace falta volver a preguntarle salvo que la verificación falle.

## No tocar

- No reeditar los adaptadores si la lectura cuadra.
- No commitear el playbook desde aquí.
- El h310 es casa de Kz. No correr `house-create`.
