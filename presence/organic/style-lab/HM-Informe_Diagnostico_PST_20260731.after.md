# Informe Técnico de Diagnóstico Definitivo — Carga PST (Hecho en México)

**Fecha:** 31 de julio de 2026  
**Elaborado por:** Equipo Cognitio — Eduardo Pillado  
**Para:** Josué Mata / Gonzalo Rodríguez Lara / Equipo Técnico Hecho en México  
**Asunto:** Dictamen técnico definitivo sobre ingesta de archivos PST y propuestas de ajuste  

---

## 1. Resumen Ejecutivo

El **diagnóstico en frío de los 5 archivos PST** (65.52 GB) identifica por qué los correos reportados no figuraban en PostgreSQL: **no hubo corrupción** ni incompatibilidad de carpetas.

### Conclusiones Principales:
1. **Ubicación real de los correos:** Los correos de ejemplo (*Legal Japifon*, *RAICES DURANGUENSES*, etc.) **no estaban** en `respHechoenMexico_09072026-2.pst` (como se asumía), sino en `respHechoenMexico_27032026.pst` (marzo de 2026).
2. **Comportamiento actual del sistema (filtro por adjuntos):** En el servicio `qa-service-filereader` (`file_reader_service.py`), la persistencia en base de datos (`guardar_en_postgres()`) opera **dentro** del ciclo de procesamiento de adjuntos. Por esa regla, **los correos sin archivos adjuntos** (sin adjuntos; p. ej. *Legal Japifon* con 0 adjuntos) **no se registran**. *Queda por confirmar con el cliente si se desea modificar este comportamiento para incluir correos sin adjunto.*
3. **Mapeo de remitente (mecanismo de respaldo):** En archivos PST de Outlook, la propiedad `sender_email_address` suele ser nula y solo queda `sender_name` ("RAICES DURANGUENSES"). Sin encabezado SMTP `From:`, el sistema asigna `desconocido@dominio.com`; por eso las búsquedas por email exacto devolvían **0 filas**.
4. **Integridad de archivos:** **0% de corrupción.** Los 5 archivos PST se leyeron completos (**13,846 mensajes** en total).

---

## 2. Censo de Archivos PST (Resultados del Escaneo)

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

> [!IMPORTANTE]
> **Sobre los respaldos del cliente:**
> Se detectaron **103 correos duplicados de forma idéntica** (misma firma: remitente + fecha + asunto) entre distintos archivos PST.
>
> La tasa es **0.74%** del acervo. Los archivos entregados en distintas fechas **no son solo exportaciones diferenciales**: contienen información traslapada. Conviene mantener la deduplicación estricta en base de datos para evitar registros repetidos en re-procesamientos.

---

## 4. Evidencia Específica de los Ejemplos Consultados

Al inspeccionar el contenido de los mensajes dentro de `respHechoenMexico_27032026.pst` **durante el análisis**:

| Remitente en PST | Asunto | Fecha en PST | Adjuntos | Estado en Sistema |
|------------------|--------|--------------|----------|-------------------|
| **Legal Japifon** | Solicitud de seguimiento para registro... | `2025-11-05 19:02` | **0 adjuntos** (sin adjuntos) | ⏸️ No registrado por la regla actual (0 adjuntos). |
| **RAICES DURANGUENSES** | REGISTRO DE LA MARCA | `2025-11-11 22:18` | **4 adjuntos** | ⚠️ Registrado con email `desconocido@dominio.com` por ausencia de header SMTP. |

---

## 5. Plan de Trabajo y Estimación de Esfuerzo (Dev-Hours)

Si se autoriza actualizar el comportamiento para incorporar correos sin adjuntos y mejorar el mapeo de remitentes:

### Tareas de Desarrollo:
1. **Ajuste de lógica de persistencia (2 hrs):** Sacar `guardar_en_postgres()` del ciclo de adjuntos para registrar mensajes con 0 adjuntos (sin adjuntos).
2. **Mejora en extracción de remitente (2 hrs):** Fallback hacia `sender_name` y parseo cuando `sender_email_address` o el header `From:` sean nulos.
3. **Pruebas de ingesta y validación (2 hrs):** Pruebas unitarias e ingesta controlada en ambiente QA.

* **Estimación total de desarrollo:** **6 horas / dev**
