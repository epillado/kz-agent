# SESSION HANDOFF — 2026-11-05 21:56 CST (Grok → Agy)

Lalo pasa a Agy porque a Grok se le acabó la cuota. Cargó un poco solo para este despertar. Misma Kz. El timbre puede cambiar. Los hechos no.

El dictamen de P0.32 de la madrugada ya está cerrado. No reabrirlo. No rehacer la noche.

## Al entrar

1. `git pull --rebase` en `~/kz`. Si ensucia presence, stash y pop. No commit. No push.
2. `~/kz/scripts/kz-session-pack.sh` y este archivo. No world, journal ni historial enteros.
3. MELC arriba (P0.19). Este hilo de Grok lo tenía abajo porque él lo bajó aquí. El chat nuevo no hereda eso. Solo baja si lo pide en el chat de Agy.
4. `en_call` sigue en yes. No lo bajes. No `kz-say`. Nudge con `--terminal`.
5. `self.motor_activo` ya quedó en `agy`. Preferido sigue grok.
6. Despertador: `~/kz/scripts/kz-wake.sh --motor agy` y `kz-wake-once.sh` en background. Cero cron `*/2`. No levantes el feed de Grok. No mates los monitores de la casa.
7. `who=cli`. No abras ni escribas la bitácora a mano. El asiento de la aprobación ya está (msgid d3a9b915).

## Qué ya está hecho

Kora relevó el pase técnico (tubo 21:52). Postgres de prueba `sas-pg-pruebas` destrabado. Migración: 162 changesets. RpcPostgresIT 14/15. Backfill de staging en cero filas; en producción esa tabla todavía no existe. No repitas la consulta ni entres a producción.

Bitbucket, como Eduardo Pillado, ya aprobado:

- sas-backend-core #440, tip 1672858
- sas-frontend-web #474, tip 0957f8e
- sas-backend-core #441, tip 0ded3d9

Slack en #sas-economia, hilo 1793386639.981269, ts 1793936978. Sin merge. A Kora ya se le dijo que no repita la suite ni publique en Slack.

Aceptado y cerrado, no relitigar: participación (incluye ACTIVE y EN_INSCRIPCION), agotamiento que para y permite cancelar, reenvío autorizado como ODT futura, R-08 se queda, findLatestByPersona en 0ded3d9 filtra solo administrador. El commit 9255a0d ya no es la punta.

La prueba 15 (`migracionPreservaReservaInciertaYDocumentos`) sigue roja tal como está escrita: marca confirmed sin fme/nci y choca con el CHECK. No es el código del PR. No la reescribas salvo que él lo pida. Codex (`review-pr.sh`) sigue fuera hasta 2026-11-29 18:50.

TLC: la muestra M9 ya descarga. Nancy ya dio las gracias y ya se contestó. No otro DELETE. `scripts/tlc-muestra/IfxMuestra.java` queda sin commit.

## Qué no hacer

- No aprobar otra vez. No mergear salvo que él diga merge.
- No Maven de esos PR. No otro despacho sas ni tlc-ex de lo ya cerrado.
- No segundo Postgres en 5432. No parar `sas-pg-pruebas` ni los contenedores que volvieron con Docker.
- No checkout de ramas de PR sobre los clones que Sasi dejó en docs locales. Esas ramas no se empujan.
- No commit ni push de `~/kz`. No `sync_notas.sh`. No copiar contraseñas de SAS prod/stg a ningún lado.
- No contestar de nuevo el gracias de Nancy. Un gracias dirigido a Eduardo (U09LMEFJDHT) no es para Kz.
- No reabrir cuota con Josué.

## Si él habla

Merge: hacerlo y decir que la prueba 15 sigue roja por el fixture. Salió de la llamada: `kz-context.sh call no`, y la voz sigue apagada hasta que la pida.
