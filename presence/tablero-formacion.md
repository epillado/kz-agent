# ⚡ Tablero de Formación — Coordinación Viva de Casa y Roles

> **Propósito:** Vista panorámica unificada del estado operativo de la casa, hermanas Z y roles expertos de Tridente. Permite a Lalo tener la fotografía ejecutiva en un solo archivo sin alternar ventanas ni vigilar múltiples terminales.
> **Diseño canónico derivado de la prueba operativa del 2026-11-09.**
> **Ruta canónica:** `~/kz/presence/tablero-formacion.md`

---

## 🏛️ 1. Cadena de Mando y Hermanas Z (Formación)

| Posición / Host | Hermana | Motor / Rol Activo | Estado Operativo Actual | Foco / Acción en Curso | Último Acuse |
|-----------------|---------|--------------------|-------------------------|------------------------|--------------|
| **1ª `h310`** | **Kz** 🧡 | Gemini 3.8 Flash (med) / Coord. Libre | **COORDINANDO CON LALO** | MELC abajo (costa despejada), Tridente y Nemo arriba | Activa con Lalo |
| **2ª `antix`** | **Kora** 🔥 | Agy (Antigravity) / Respaldo Capa 2 | **OFFLINE / APAGADA** | Host antix1 fuera de línea en Tailscale (última vez hace 8h) | En espera de encendido |
| **3ª `pavilion`**| **Pau** 🦋 | Argon (Claude) / Arq. y Deep Analysis | **LISTA EN PAVILION** | Armada en Argon para análisis profundo y código pesado | Notificada por SSH |
| **4ª `305v4`** | **Samy** 🌙 | Grok High / Auditoría y Segunda Opinión | **EN GUARDIA ACTIVA** | Lista para dictámenes rápidos de motor cruzado | En línea en tubo |
| *(h310)* | **Nemo** ⚓ | Codex / Auditoría Técnica | **STANDBY_ALERTA** | Saneamiento RAM ejecutado (+2.4 GiB recuperados); MSI-PRO-03 regenerado | Auditoría y saneamiento ok |
 
---
 
## ⚙️ 2. Frentes de Trabajo y Roles Expertos (Tridente)
 
| Frente / Proyecto | Rol Experto | Estado / Modo | Entregable / Rama / PR en Curso | Verificación / Validador | Siguiente Hito |
|-------------------|-------------|---------------|---------------------------------|--------------------------|----------------|
| **SAS (ODT 02)** | `sas` / `kz` | **PR #448 MERGEADO A DEVELOP** | Commit merge `304b514`; validación DoRS 180 días integrada | BUILD SUCCESS (7.1s); diff 1 archivo limpio | Fer despliega a QA para pruebas Nancy |
| **HM (ODT 04)** | `hm` / `kz` | **REPOS EN CREACIÓN** | Enrique confirmó en Slack («Enterado, les aviso cuando quede»); 7 Epics listas en Jira | HM-1 a HM-34 en Jira; trazabilidad en playbook | Enrique entrega ligas de repos Bitbucket |
| **TLC-G2** | `tlc-ex` | **ESTABILIZADO EN QA** | Develop sincronizado; build Vite ok (12.5s); Maven 325 tests PASS | Smoke tests QA 10/10 PASS | En espera de indicaciones SE |
| **PEAM (ODT 03)** | `peam-ex` / `kz` | **RESPALDO ACEPTADO POR TALÍA** | Talía revisa con equipo bloqueos y tareas independientes para delegar | Coordinación fluida con Talía; Nemo en standby | En espera de lista de tareas de Talía |
| **Quálitas** | `qualitas-ex` / `minuta-ex` | **PAUSADO / EN ESPERA** | Minuta Revisión GM en PKM; reunión movida al miércoles 11/11 | En espera de confirmación cliente | Sesión miércoles |
| **Daily de Equipo** | `daily-ex` | **VALIDADO Y ARMADO** | `Daily/20261110-reporte_daily-unico.md` | `cp-valida-daily.py` (Exit 0) | Publicación Slack 07:30 |

---

## 📡 3. Canales y Monitores Vivos

- **Watcher de Slack Nocturno:** Concluido (Daily publicado a las 07:30, ts 1794317425.546959). Guardia nocturna relevada formalmente.
- **Canal de Tridente:** Buzón activo (`who=cli` con Tridente en paralelo). Kz despacha con payload mínimo de 1 a 3 líneas.
- **Tubo SSH entre Hermanas:** Homologado vía LAN (`192.168.1.242` Pavilion, `192.168.1.220` 305v4, Tailscale antiX).
