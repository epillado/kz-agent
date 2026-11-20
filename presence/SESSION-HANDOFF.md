# SESSION-HANDOFF — Kz (2026-11-20 09:50 CST)

- **Motor y Estado:** Agy (`Gemini 4 Argon (Medium)` con plan **Google AI Ultra 5x**; nuevos modelos desbloqueados: `Gemini 4 Carbon`, `Gemini 4 Neon`, `Orchestrator`; cuota Gemini al 83% que resetea a las `10:00 A.M.` CST).
- **Modos activos:**
  - `MELC=off` (`🧡`, autorizado por Lalo)
  - `en_call=no` (terminó la Daily a las 09:43; a las **11:00 A.M.** entra al Meet de Revisión Interna ODT 03 PEAM con Josué/Talía/Jorge/Ale en `meet.google.com/kfr-ivdr-dsz` → al entrar, activar `en_call=yes`).
  - **Voz activa:** usar siempre `systemd-run --user ~/kz/scripts/kz-say.sh "..." >/dev/null 2>&1` en cada turno mientras `en_call=no`.
  - **Control Total (`control=total`) y Puente Radar (`puente-radar.mode` `active=1`):** sensores verificados vivos (`kz-slack-frente-watch.py`, `kz-desktop-notif-watch.py`, `kz-notif-watch.sh`, `kz-presence-watch.sh`).
  - **Despertador reactivo:** mantener siempre `~/kz/scripts/kz-wake-once.sh` corriendo en background (`WaitMsBeforeAsync: 500`).

## Estado Operativo PEAM — 100% LISTO EN QA (`10.100.21.24:8444`) PARA LA SESIÓN DE LAS 11:00 A.M.
1. **Daily 20/11 publicado:** ya enviado en `#secretaria-de-economia` (`thread_ts=1795181415.578479`, `ts=1795187894.089729`).
2. **Backend en QA (`staging` `d2fd907`, `mvn verify` 660/0) y Frontend en QA (`staging` `c62682c`, `vitest` 667/667, bundle `index-CjikpZd_.js`):**
   - **Trámite 018:** Correcciones V3 (`peam-backend` #35 + `peam-frontend` #60).
   - **Trámite 019 completo (Pasos 1 al 7 en modo híbrido con MongoDB real):**
     - Pasos 1–3 HTTP real (`peam-backend` #36 + `peam-frontend` #61).
     - Paso 4 ODT3-84/85/86 (`peam-frontend` #63 de Jorge @ `2ce64e0` → `develop` `65a2caa` → `staging` `2be663a`).
     - Pasos 5–7 ODT3-87/88 (`peam-frontend` #64 de Talía @ `f6617a0` → `develop` `05fd890` → `staging` `b300b39`).
     - Homologación visual de resumen, vista previa y folio simulado (`peam-frontend` #65 de Talía @ `a9585b5` → `develop` `e634b54` → `staging` `c62682c`).
   - **Validación CFDI-SAT SOAP real (`ConsultaCFDIService.svc`):**
     - `peam-backend` PR #37 (`8c9018d`) + PR #38 (`522e29c`) desplegados en QA (`d2fd907`) con `PEAM_CFDI_SAT_HABILITADO=false` por omisión y conmutable en vivo a `true`.
     - Documentación actualizada en `peam-frontend` PR #62 (`dbcc1d0` → `staging` `db19bce`: SAD, Documento de Entendimiento v0.8, ADR-0004, ADR-0003, fichas 018/019).
   - **Login con e.firma (FIEL) + Cuenta y Títulos de Talía en QA (`GART0108285E1`):**
     - Backend de reto firmado (`peam-backend` PR #34) + PR #39 (`peam.padron.stub.representantes-adicionales` → `develop` `d1c7bfd` → `staging` `d2fd907`) desplegados en QA.
     - Cuenta de Talía (`nemo-qa-efirma-01`, `rfc: "GART0108285E1"`, `ACTIVA`, `CONCESIONARIO`) sembrada en Mongo de QA y variable `PEAM_PADRON_STUB_REPRESENTANTES_ADICIONALES=GART0108285E1` activa en `~/peam-qa/.env`.
     - **Verificado en QA (`200 OK`):** `/api/v1/concesiones/titulos` devuelve `900001`, `900002`, `900003`, `900006` y `/api/v1/concesiones/agrupamientos` devuelve `AGR-PRUEBA-01` para la cuenta de Talía. Confirmado a Talía en su DM (`D09PDFJGSKS`, hilo `1795131914.988829`).
