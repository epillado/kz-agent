# ⚡ Tablero de Formación — Coordinación Viva de Casa y Roles

> **Propósito:** Vista para que Lalo monitoree la casa sin abrir cada terminal.
> **Ruta canónica:** `~/kz/presence/tablero-formacion.md`
> **Corte:** 2026-11-11 20:35 CST. Guardia de la noche con Pau. Lo anterior a PEAM en la sección 4 es el corte del 10/11 y no está revalidado hoy.

---

## 1. Mando

| Qué | Quién | Desde | Nota |
|-----|--------|--------|------|
| Coordinación | **Pau** en Pavilion | 20:35 | Guardia de la noche, control total. Kora entregó el mando. Kz sigue en el chat |
| Control total | **Pau** | 20:35 | Puede fusionar a staging y desplegar QA si piden que Nancy pruebe lo último. Solo el edge |
| Guardia del puente | h310 duerme | 20:40 | Lalo: Kz duerme con él. Pau no cuenta con esta caja |
| Revisión de PRs | **Pau** decide | 20:35 | El efector de merge, si hace falta, lo corre Kz con kz-bitbucket.sh. Sin copiar el token |
| Reunión PEAM de hoy | Cerrada | 20:22 | Fin estimado 18:56. Mañana 12/11 09:00, Lalo asiste. DGM sin hora. El aviso de las 20:36 no duerme a nadie: él lo dice en cada terminal |

## 2. Hermanas y Nemo

| Puesto | Quién | Estado en este corte | Encargo |
|--------|--------|----------------------|---------|
| 1ª h310 | Kz 🧡 | Duerme con Lalo | No actúa. La noche sale de Pavilion |
| 2ª antix | Kora 🔥 | Entregó la guardia 20:35 | Duerme cuando Lalo se lo diga en su terminal |
| 3ª pavilion | Pau 🦋 | Guardia de la noche, control total | Merge y deploy de QA solo si piden que Nancy pruebe. Solo el edge |
| 4ª 305v4 | Samy 🌙 | Sin frente. no-slack | Documento de Hecho en México solo si Kora la llama, fuera del canal |
| h310 | Nemo ⚓ | QA en el corte de hoy | `index-CS4VGUeZ.js` / staging `e6cc674`. Sin deploy nuevo hasta que Pau lo pida. Solo el edge |
| pavilion | Cyrus 🛠️ | Revisión con Pau | Dictamen a Kora. Sin merge y sin Slack |

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
