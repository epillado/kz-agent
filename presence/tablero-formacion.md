# ⚡ Tablero de Formación — Coordinación Viva de Casa y Roles

> **Propósito:** Vista para que Lalo monitoree la casa sin abrir cada terminal.
> **Ruta canónica:** `~/kz/presence/tablero-formacion.md`
> **Corte:** 2026-11-25 16:18 CST. Control total en h310 (Kz en Hydrogen Medium). Cuota protegida: trabajo técnico a Cyrus/Nemo/Tridente; RAM h310 protegida mandando compuertas pesadas a Cyrus.

---

## 1. Mando

| Qué | Quién | Desde | Nota |
|-----|--------|--------|------|
| Coordinación | **Kz** en h310 | 11:20 | Control total. who=cli: no escribe Bit/ |
| Puente radar | **Kz** en h310 | 11:20 | Único. Sin replay. Gordos a Tridente con --no-dispatch |
| Revisión de PRs | Rol experto, Kz fiscaliza | 11:20 | #482 a sas. #53 a peam-ex. Merge solo con triple verde |
| Junta | Revisión de insumos PEAM | 09:55 | Abierta. Grabación desde 10:32. Al inicio habla Josué |

## 2. Hermanas y Nemo

| Puesto | Quién | Estado en este corte | Encargo |
|--------|--------|----------------------|---------|
| 1ª h310 | Kz | Despierta, Hydrogen Medium, control total | Puente, triage, despacho 1-3 líneas, fiscalización |
| 2ª antix | Kora | Despierta, GPT-OSS 120B, no-slack | Segunda opinión puntual / desempate neutral |
| 3ª pavilion | Pau | Despierta, GPT-OSS 120B (Medium), no-slack | Respaldo en Pavilion si Cyrus ocupa apoyo |
| 4ª 305v4 | Samy | Arriba, Grok 4.7, no-slack (305v4 5.5 GiB libre) | Segunda opinión ágil y lectura rápida |
| h310 | Nemo | Activo (Codex Corp) — sin builds pesados en h310 | Slack/Git/Jira; delegar compuertas pesadas a Cyrus (Pavilion) |

## 3. PEAM, vivo ahora

| Pieza | Estado | Evidencia |
|-------|--------|-----------|
| Frontend en QA | Corte de la noche | `index-CS4VGUeZ.js`, staging `e6cc674`. Solo el edge. Sin compose down y sin recrear backend ni Mongo. Túnel de h310: https://localhost:8444/ |
| Commit | staging `e9e3f45` (PR #34, incluye Talía `5a131d9`) | Acuse de Nemo 11:51. Solo se recreó el servicio `edge` |
| Backend y Mongo | Intactos | `origin/staging` del backend está vacío. No hubo `docker compose down` |
| Paquete | PR #35, SHA `f8e6bab` | Historial de los pasos 2 a 4 elevado al asistente. La persona elegida rige el paso 4. 275/275, build y lint de `src/` en verde. Sin merge |
| SHA en revisión | `c96b34b` | Compuertas verdes (276, lint, build). No se mergea: la persona se ve en el resumen y no se guarda. Al reabrir vuelve el titular original. Además el front deja «entre calles» vacío y el backend `14d5856` lo exige |
| Límite de recarga | Sigue | Si recargan la página, la persona no queda en `Datos018`. Alejandra no pidió eso |
| Backend PR #13 | MERGED 12:57 | SHA `e9dd5d4` en develop, commit de merge `75825e3`. Verde de Nemo, Pau y Cyrus. «Entre calles» opcional. Teléfono local y correo adicional obligatorios al completar |
| Back PR #14 | MERGED 13:58 | `defcdae` en develop, commit `0567009`. Verde de Nemo, Pau y Cyrus. No toca resguardos |
| Front `5bbf301` | NO de Nemo, Pau y Cyrus | En origin. Recarga corregida. Resguardo en el payload y títulos visibles en individual. Sin merge |
| Front `554b7ba` | NO de compuerta, superado | Cyrus 16:32: 311 PASS / 1 FAIL, 5021 ms. Nemo 16:34: el wizard perdía el signo y un -5 quedaba como 5. No es cierre |
| Front `a2eedf6` | En QA 16:57 | Nemo aprobó. Pau y Cyrus NO por el total 795. Lalo ordenó publicar lo listo. Develop `5778264`, staging `d36c3a6`. Edge nuevo `index-BeqtuLsn.js`. Lista y aviso de recarga en el hilo de QA |
| Total 795 | En QA, visto desde h310 18:06 | `https://localhost:8444/` HTTP 200, bundle `index-CS4VGUeZ.js`. Túnel por Pavilion hacia `srvqasas`. staging `e6cc674` |

## 4. Corte del 10/11, no revalidado hoy

| Frente | Último dato del tablero anterior |
|--------|-----------------------------------|
| SAS | PR #449 mergeado a develop, commit `13ceb04` |
| Hecho en México | Repos creados, sin scaffolding en ese corte |
| TLC-G2 | QA estable, smoke 10/10 |
| PEAM de ese corte | PR #7 back y PR #26 front. Lo de hoy está en la sección 3 |
| Quálitas | Hoy 16:00–17:00, Teams. Stephanie avisó en #soporte-qualitas a Fernando y a Andrés: sesión para las listas. La invitación la manda ella |
| Daily | `Daily/20261110-reporte_daily-unico.md` armado para las 07:30 |

## 5. Canales

- Tridente: `who=cli`. Kz deja asiento y no escribe la bitácora a mano.
- Puente Radar: activo en h310 desde las 11:20. Desde las 17:10 Kora decide y Kz retransmite. Nadie más lo duplica.
- Hecho en México, 17:18: Kora fusionó el PR #2 de `hecho-en-mexico-frontend`. `develop` quedó en `e685430`. La rama `docs/entendimiento-hm` sigue en `2436e9b`. El canal no se contesta desde h310.
- Sensores de casa en h310: vivos desde las 09:12.
