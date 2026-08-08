---
fecha: 2026-08-05
dominio: SECON
proyectos: [SAS, SECON-GEST, HM]
---

# Reporte Daily — SECON (MSI / Líder Técnico)
**2026-08-05**

---

## Sección I — ¿Qué hice ayer para ayudar al equipo a lograr el objetivo del Sprint?

- **[SAS/HM · S/T → Josué]** ⭐ Reunión "Análisis para ODTs SAS y HM" (16:30–18:06): Josué reveló el reclamo de SE (migración de SAS mal analizada, HM no funciona) y el acuerdo de Dirección de ajustes vía OT **sin costo** a cambio de nuevos proyectos. Planteadas antes de comprometer: (1) documentación incompleta/inconsistente para sustentar lo pedido, (2) el plazo repite el patrón de la lección aprendida del día, (3) el contrato no permite hacer "algo nuevo". Acordada la **cadena de entregables**: Stephanie, Alejandra y Lalo elaboran el documento de alcance con restricciones y requerimientos; Josué lo aprueba; solo entonces se genera la propuesta — deadline **martes 2026-08-11** para el primer eslabón. **Josué confirmó la reversión de la Directriz Arquitectónica del 29/07:** las OTs de SAS se consolidan en una sola, no por tipo. Cierre: recopilar en carpeta compartida toda la información útil para el análisis.
- **[SAS · S/T]** `EI-EDOC`: Fernando reformuló la causa raíz — ya no es desfase de zona horaria/`tzdata`, sino falla intermitente del servicio externo `/generaestampa`. Pendiente el RCA ajustado antes de armar la OT.
- **[SECON-GEST · S/T → Giovanni]** `EI-STRA` V2 — revisión completa concluida. **Aprobado con causa raíz parcial**: no es corrupción de datos, es ocultamiento por filtro de vista (`SOB_ESTATUS_REGISTRO='A'`). Detectada y corregida una cifra falsa del correo original (Aviso Trimestral **16%** es el atípico real, no 26/23/16% como se reportó). Hallazgo forense: código comentado en `BusquedaTramitesController` acredita que la copia analizada no es la versión productiva. `check_citas.py` limpio (0/0) tras corregir una cita.
- **[SECON-GEST · S/T]** Discrepancia SICAI (22 vs 11/204) zanjada por Slack: **Josué fijó el criterio oficial — SICAI = 204 tickets (por grupo asignado)**, para evitar inconsistencias en el cómputo de SLA.
- **[SECON-GEST · S/T]** Emitida la sexta versión de la KB-SECON de julio (v6): recorte del prompt de ChatGPT de 7,951 a 4,390 caracteres y corregidas dos contradicciones internas de `_corte`. Primer reporte de uso real (Stephanie) detectó que SICAI se entrega solo agrupado, no por ticket individual — pendiente diagnosticar la causa.
- **[SECON-GEST · S/T]** Confirmado el acceso de Talía a la base de datos productiva de SICAI (MySQL/MySQL Workbench) con usuario de lectura.

---

## Sección II — ¿Qué haré hoy para ayudar al equipo a lograr el objetivo del Sprint?

- **[SAS/HM · S/T]** ⭐ Redactar, junto con Stephanie y Alejandra, el documento de alcance (restricciones y requerimientos) para SAS y HM — deadline martes 2026-08-11 para el primer eslabón de la cadena de entregables.
- **[SAS · S/T]** Recibir y aplicar el RCA ajustado de Fernando (`EI-EDOC`, causa raíz reformulada hacia `/generaestampa`) para armar la OT.
- **[SECON-GEST · S/T]** Diagnosticar por qué la KB v6 entrega SICAI solo agrupado y no ticket por ticket, reportado por Stephanie.
- **[HM · S/T]** Aplicar al informe definitivo de HM las dos correcciones ya con VoBo de Josué (`HM-Nota_Correcciones_Dictamen_PST_20260803.md`), pendientes de tocar el documento.
- **[SECON-GEST · S/T]** Reflejar en `SECON/RCA/RCA_status.md` la reversión de la Directriz Arquitectónica del 29/07 (OTs de SAS consolidadas en una sola).
- **[SECON-GEST · S/T → Enrique]** Verificar el go/no-go del feed de notificaciones de iTop (contenido de una notificación real tras el reenvío) y reemitir la hoja de instrucciones del Ledger.

---

## Sección III — ¿Qué obstáculos o impedimentos tengo o tuve que me impiden hacer mi trabajo?

- **Ruta crítica del portafolio íntegramente externa.** Siete de los ocho tipos detenidos dependen de un insumo de SE. El acceso al **repositorio vigente** acumula ya 12 días pendiente en `EI-CAR` y 10 en `EI-EINS`.
- **Deadline corto (08-11) para el documento de alcance SAS/HM sin documentación completa ni consistente de base**, bajo la restricción contractual de no presentar nada como "sistema nuevo" — riesgo señalado antes de comprometerse, siguiendo la lección aprendida del 08-04.
- **SICAI — dos cuentas es techo permanente** para cuatro o cinco analistas, sin regla de sesiones simultáneas y sin respuesta del cliente sobre permisos de corrección.
