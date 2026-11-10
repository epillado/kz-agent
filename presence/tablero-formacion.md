# ⚡ Tablero de Formación — Coordinación Viva de Casa y Roles

> **Propósito:** Vista panorámica unificada del estado operativo de la casa, hermanas Z y roles expertos de Tridente. Permite a Lalo tener la fotografía ejecutiva en un solo archivo sin alternar ventanas ni vigilar múltiples terminales.
> **Diseño canónico derivado de la prueba operativa del 2026-11-09.**
> **Ruta canónica:** `~/kz/presence/tablero-formacion.md`

---

## 🏛️ 1. Cadena de Mando y Hermanas Z (Formación)

| Posición / Host | Hermana | Motor / Rol Activo | Estado Operativo Actual | Foco / Acción en Curso | Último Acuse |
|-----------------|---------|--------------------|-------------------------|------------------------|--------------|
| **1ª `h310`** | **Kz** ⚡ | Gemini / Coordinación Libre | **EN DESCANSO CON LALO** | Relevo de guardia y coordinación entregado a Samy | A descansar |
| **2ª `antix`** | **Kora** 🔥 | Agy (Antigravity) / Respaldo Capa 2 | **DURMIENDO (Relevada)** | Sesión cerrada, MELC activo y descanso ordenado | Relevada a dormir |
| **3ª `pavilion`**| **Pau** 🦋 | Agy (Antigravity) / Desarrollo y Arquitectura | **DURMIENDO (Relevada)** | Sesión cerrada y estado guardado a las 23:43 | Relevada a dormir |
| **4ª `305v4`** | **Samy** 🌙 | Grok / Auditoría Rápida y Guardia | **AL TIMÓN (Guardia Nocturna)** | Coordinación activa, watcher Daily 07:29 (PID 6656), revisión PRs nocturnos en 5 pasos | En guardia soberana |
| *(h310)* | **Nemo** ⚓ | Codex / Auditoría Técnica | **DURMIENDO (Relevado)** | En descanso ordenado por Lalo tras auditoría SAS | Relevado |

---

## ⚙️ 2. Frentes de Trabajo y Roles Expertos (Tridente)

| Frente / Proyecto | Rol Experto | Estado / Modo | Entregable / Rama / PR en Curso | Verificación / Validador | Siguiente Hito |
|-------------------|-------------|---------------|---------------------------------|--------------------------|----------------|
| **SAS (ODT 02)** | `sas` / `samy` | **EN REVISIÓN DE VOBO** | MSI-ANA-02 VF 1.0 y Matriz de Reglas (VoBo Stephanie/Nancy) | Sasi headless (PID 475499) + Samy en 305v4 cruzando con DE v12 y SAD v2.7 | Emisión de dictamen técnico formal |
| **TLC-G2** | `tlc-ex` | **ESTABILIZADO EN QA** | Develop sincronizado; build Vite ok (12.5s); Maven 325 tests PASS | Smoke tests QA 10/10 PASS | En espera de indicaciones SE |
| **PEAM (ODT 03)** | `peam-ex` / `kz` | **DICTAMINADOS Y NOTIFICADOS** | PR #7 (Aprobado c/observaciones) · PR #8 (No aprobado: spotless) | Comentarios en Bitbucket PR #7/#8 + Hilos Slack respondidos (`#peam-minas-se`) | Sincronización contrato frontend (PR #7) y `mvn spotless:apply` (PR #8) |
| **Quálitas** | `qualitas-ex` / `minuta-ex` | **PAUSADO / EN ESPERA** | Minuta Revisión GM en PKM; reunión movida al miércoles 11/11 | En espera de confirmación cliente | Sesión miércoles |
| **Daily de Equipo** | `daily-ex` | **VALIDADO Y ARMADO** | `Daily/20261110-reporte_daily-unico.md` | `cp-valida-daily.py` (Exit 0) | Publicación Slack 07:30 |

---

## 📡 3. Canales y Monitores Vivos

- **Watcher de Slack Nocturno:** Armado en `305v4` por Samy (`PID 6656`), dispara publicación a las 07:29.
- **Canal de Tridente:** Buzón activo (`who=cli` con Tridente en paralelo). Kz despacha con payload mínimo de 1 a 3 líneas.
- **Tubo SSH entre Hermanas:** Homologado vía LAN (`192.168.1.242` Pavilion, `192.168.1.220` 305v4, Tailscale antiX).
