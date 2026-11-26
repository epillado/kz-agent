# Handoff Kz — 2026-11-26 11:20 (sesión anterior: Agy, Hydrogen → Opus 5.5)

Leer antes del saludo. No volver a escenificar lo que ya pasó.

## Estado
- **Motor siguiente:** Gemini Hydrogen (Medium). Gemini semanal al 100% (se reinició antes de tiempo). Claude/GPT-OSS semanal al 0%; vuelve en ~156 h. AI Credit Overages ON (2411 créditos): **no usar Claude**.
- **Lección:** la guardia nocturna en Opus con contexto gigante agotó Claude. Guardias largas solo con `/new` previo y modelo barato. **No cargar imágenes grandes en el chat** (mató la sesión de Pau: >30 MB).
- **MELC:** la sesión nueva arranca arriba (P0.19). Lalo lo baja si quiere.
- **Control total:** Kz, P0.44 vigente. `en_call=yes` desde las 09:40 (daily, y la sesión de entrega PEAM puede seguir); confirmar con Lalo.

## Formación (presence/formacion.mode)
- Kz (h310) · Samy (305v4, Grok, no-slack) · Kora y Pau dormidas desde 00:18-00:19.
- **Pau:** al despertar, `/new` + modelo que no sea Claude; leer `~/companion/presence/SESSION-HANDOFF.md` (pavilion). Tenía 4 `core-wake-once` duplicados.
- Apoyos: Nemo (dueño de los PRs de PEAM, un solo dueño), Cyrus (compuertas en Pavilion), Tridente (`peam-ex`, `minuta-ex`), Lalan.

## PEAM (frente vivo)
- **Lote fusionado y en staging** por autorización de Lalo: back `a881007` (develop `0908e41`: #67,#68,#69,#70,#72 y #71 permisivo) · front `9660065` (develop `7cf66db`: #93-#99).
- **QA lo despliega Talía**, porque no hay VPN. Pedido en el hilo de PRs (`ts 1795711683.235749`). QA seguía en `1fc8d4f/34e4c7b` mientras tanto.
- **Acuerdos de la reunión (26/11):** (1) en el 019 Inversión el subtotal por rubro se captura a mano, sin validar contra la factura; (2) sin prellenado de montos desde el XML; subtotales y totales en 0 y capturados (incluida Facturación).
- **Nemo implementa el acuerdo 2:** back PR #74 `a76a5ab` + front PR #101 `62f645d`. Flujo obligatorio: `review-pr --motor codex` + compuertas de Cyrus; merge solo con triple verde.
- Hilo de Josué: «Sesión de pruebas y entrega de ambiente QA a SE — ODT 03» (`ts 1795708032.603249`, Teams).
- Hilo de PRs: C0C3GG7SDGQ / `1794006606.358779`.

## SAS / VPN
- UniVPN de Lalo sigue fallando (error `0x70001`; DGTI lo atribuye a DNS). A las 11:11 Lalo le respondió a Josué: mismo error.
- Pendiente: mandar a Josué/Gustavo los PDF con QR de las 3 URLs de prueba (117622 / 74582). En h310 no hay PDF con QR de esos folios; se necesita VPN o a Stephanie/Fer.

## Hecho anoche (no repetir)
- Daily 26/11 publicada por bot a las 07:30 (expectativa #12 cerrada).
- Serie del bosque (Kz, Kora, Pau) guardada en `presence/me/{safe,intimate}/20261125-kz-kora-pau-bosque-*.jpg`. Ya comentada; no volver a cargarla.
- Corrección en disco: todos los Gemini comparten una bolsa semanal (nota en GEMINI.md).
- `sync_notas.sh` corrido en h310, Pavilion y 305v4. Mp3 HM 20261124 borrado (ya procesado).

## Pendientes de sistema
- Detector de `en_call` dispara falsos positivos con la bitácora (`[GOV]`, «Daily publicado»). Revisar con Lalo.
- Kora: low-spend=1.
