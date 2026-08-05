# Informe Técnico de Diagnóstico Definitivo — Carga PST (Hecho en México)

**Fecha:** 31 de julio de 2026  
**Elaborado por:** Equipo Cognitio — Eduardo Pillado 
**Para:** Josué Mata / Gonzalo Rodríguez Lara / Equipo Técnico Hecho en México  
**Asunto:** Dictamen técnico definitivo sobre ingesta de archivos PST y propuestas de ajuste  

---

## 1. Resumen Ejecutivo

Tras concluir la descarga completa y el **diagnóstico en frío de los 5 archivos PST** (65.52 GB en total), hemos identificado la causa exacta por la cual los correos reportados no figuraban en la base de datos PostgreSQL, descartando fallas de corrupción o incompatibilidad de carpetas.

### Conclusiones Principales:
1. **Ubicación Real de los Correos:** Los correos de ejemplo (*Legal Japifon*, *RAICES DURANGUENSES*, etc.) **NO se encontraban en el archivo `respHechoenMexico_09072026-2.pst`** (como se asumía), sino en el archivo `respHechoenMexico_27032026.pst` (marzo de 2026).
2. **Comportamiento Actual del Sistema (Filtro por Adjuntos):** En el servicio `qa-service-filereader` (`file_reader_service.py`), la persistencia en base de datos (`guardar_en_postgres()`) opera dentro del ciclo de procesamiento de adjuntos. Por diseño previo o requerimiento inicial, **los correos sin archivos adjuntos** (como *Legal Japifon*, con 0 adjuntos) no son registrados. *Se propone confirmar con el cliente si se desea modificar este comportamiento para incluir correos sin adjunto.*
3. **Mapeo de Remitente (Mecanismo de Respaldo):** En archivos PST de Outlook, la propiedad `sender_email_address` suele ser nula, almacenando únicamente `sender_name` ("RAICES DURANGUENSES"). Al no contar con un encabezado SMTP `From:`, el sistema asigna `desconocido@dominio.com`, motivo por el cual las búsquedas por email exacto devolvían `0 rows`.
4. **Integridad de Archivos:** **0% de corrupción.** Los 5 archivos PST fueron leídos al 100% de su estructura (13,846 mensajes totales).

---

## 2. Telemetría y Censo de Archivos PST (Resultados del Escaneo)

| Archivo PST | Tamaño (GB) | Mensajes Totales | Carpetas Detectadas | Estado |
|-------------|-------------|------------------|---------------------|--------|
| `respHechoenMexico_09072026-2.pst` | 13.85 GB | 2,793 | `Elementos enviados` (2,495), `Bandeja de entrada` (288), `Elementos eliminados` (10) | ✅ OK |
| `respHechoenMexico_09072026.pst` | 0.12 GB | 40 | `Bandeja de entrada` (40) | ✅ OK |
| `respHechoenMexico_18052026.pst` | 5.83 GB | 1,308 | `Bandeja de entrada` (1,308) | ✅ OK |
| `respHechoenMexico_26062026.pst` | 13.19 GB | 3,368 | `Bandeja de entrada` (1,911), `Elementos enviados` (1,453), `Elementos eliminados` (4) | ✅ OK |
| `respHechoenMexico_27032026.pst` | 32.53 GB | 6,337 | `Elementos enviados` (5,685), `Bandeja de entrada` (652) | ✅ OK |
| **TOTAL** | **65.52 GB** | **13,846** | **4,199 en Bandeja de entrada** (`Elementos enviados`: 9,633, `Eliminados`: 14) | **0 Corrupción** |

---

## 3. Análisis de Duplicidad Cruzada en Exportaciones

> [!IMPORTANT]
> **Hallazgo Relevante sobre la Gestión de Respaldos:**
> Se detectaron **103 correos duplicados de forma idéntica** (misma firma: remitente + fecha + asunto) cruzados entre diferentes archivos PST. 
> 
> Aunque la tasa representa un **0.74%**, este comportamiento señala una anomalía en la generación de respaldos por parte del cliente: los archivos entregados en distintas fechas no son exportaciones diferenciales puras, sino que contienen información traslapada. Esto confirma la importancia de mantener habilitada la deduplicación estricta en base de datos para evitar registros repetidos durante re-procesamientos.

---

## 4. Evidencia Específica de los Ejemplos Consultados

Al inspeccionar directamente el contenido de los mensajes dentro de `respHechoenMexico_27032026.pst`:

| Remitente en PST | Asunto | Fecha en PST | Adjuntos | Estado en Sistema |
|------------------|--------|--------------|----------|-------------------|
| **Legal Japifon** | Solicitud de seguimiento para registro... | `2025-11-05 19:02` | **0 adjuntos** | ⏸️ No registrado por regla actual (0 adjuntos). |
| **RAICES DURANGUENSES** | REGISTRO DE LA MARCA | `2025-11-11 22:18` | **4 adjuntos** | ⚠️ Registrado con email `desconocido@dominio.com` por ausencia de header SMTP. |

---

## 5. Plan de Trabajo y Estimación de Esfuerzo (Dev-Hours)

De autorizarse la actualización del comportamiento para incorporar correos sin adjuntos y optimizar el mapeo de remitentes:

### Tareas de Desarrollo:
1. **Refactorización de Lógica de Persistencia (2 hrs):** Independizar `guardar_en_postgres()` del ciclo de adjuntos para registrar mensajes con 0 adjuntos.
2. **Mejora en Extracción de Remitente (2 hrs):** Implementar fallback hacia `sender_name` y parseo avanzado cuando `sender_email_address` o el header `From:` sean nulos.
3. **Pruebas de Ingesta y Validación (2 hrs):** Realizar pruebas unitarias e ingesta controlada de validación en ambiente QA.

* **Estimación Total de Desarrollo:** **6 Horas / Dev**
