# Expediente de Evidencias y Ejemplos PST (Hecho en México)

**Fecha:** 3 de agosto de 2026  
**Elaborado por:** Equipo Cognitio — Líder Técnico  
**Para:** Reunión Ejecutiva con Gonzalo Rodríguez Lara / Equipo Hecho en México  
**Base de Datos de Respaldo:** `SECON/HM/indice_pst_2026.sqlite` (13,846 registros extraídos de 65.52 GB de PSTs)  

---

## Resumen Ejecutivo y Argumentación Estratégica Cruzada

El análisis estructural del acervo PST revela un hallazgo determinante que simplifica y reordena la reunión ejecutiva con el cliente:

> [!IMPORTANTE]
> **Una sola decisión de alcance (Opción B: Ingestar únicamente la `Bandeja de entrada`) resuelve de forma automática dos de las tres situaciones planteadas:**
> 1. **Elimina el 99.5% de los remitentes sin dirección** (descartando 9,619 mensajes salientes compuestos localmente que carecen por diseño de encabezados de recepción).
> 2. **Elimina el 94.2% de las copias redundantes** (descartando 194 mensajes duplicados generados por comunicaciones salientes repetidas).
> 3. **Reduce en un 70% el volumen total de ingesta y almacenamiento** en MinIO y PostgreSQL (pasando de 13,846 a 4,199 mensajes).

De este modo, la conversación con el cliente deja de ser una discusión dispersa de múltiples fallas y se concentra en **1 decisión de alcance (Opción B)** que soluciona los problemas de remitentes y duplicados, más **1 decisión de regla funcional de negocio** (definir la ingesta de correos sin adjuntos para 398 solicitudes de ciudadanos y empresas reales).

---

## 1. Censo General y Línea Base de Ingesta

El análisis de los 5 archivos PST descargados arroja un universo de **13,846 mensajes totales** con **0% de corrupción**.

### Desglose por Carpeta Original:

| Carpeta PST | Mensajes Totales | Porcentaje del Acervo |
|-------------|------------------|-----------------------|
| `Bandeja de entrada` | 4,199 | 30.33% |
| `Elementos enviados` | 9,633 | 69.57% |
| `Elementos eliminados` | 14 | 0.10% |
| **TOTAL** | **13,846** | **100.00%** |

> **Consulta de verificación en la base de índice:**
```sql
SELECT carpeta, COUNT(*) FROM mensajes GROUP BY carpeta;
```

---

## 2. Situación 1: Correos con **0 Archivos Adjuntos** (6.9% del Acervo)

Se identificaron **962 mensajes en total** con `num_adjuntos = 0` (Sin adjuntos, 6.95% del acervo completo).

### Corte Vital: Mensajes Recibidos vs. Enviados y Segmentación

- **Mensajes RECIBIDOS (`Bandeja de entrada`): 668 correos** (69.4% del volumen de 0 adjuntos). Éstos corresponden al flujo entrante y se desglosan en:
  - **398 correos de solicitantes y empresas externas (Externos Reales) no registrados:** Similares al caso de *Legal Japifon*. Bajo la regla actual del servicio, no son registrados por no tener adjuntos.
  - **252 correos internos (`@economia.gob.mx`):** Comunicaciones institucionales entre áreas.
  - **18 servicios de notificación automatizados:** Mensajes del sistema (Google Drive, WeTransfer, no-reply).
- **Mensajes ENVIADOS (`Elementos enviados`): 293 correos** (30.5%). Comunicaciones salientes del equipo Hecho en México.
- **Mensajes ELIMINADOS (`Elementos eliminados`): 1 correo** (0.1%).

> **Consulta de verificación en la base de índice:**
```sql
SELECT carpeta, COUNT(*) FROM mensajes WHERE num_adjuntos = 0 GROUP BY carpeta;
```

### Muestra Representativa de la situación 1 (18 Casos Recibidos en Bandeja de Entrada con 0 Adjuntos):

*Nota: Se enmascara la parte local de las direcciones electrónicas para protección de datos personales en la muestra pública. Los casos ancla se muestran completos para la demostración en pantalla.*

| Remitente (Nombre) | Dirección Recuperada (`email_header`) | Fecha | Asunto | Carpeta | Archivo PST | Adjuntos |
|--------------------|---------------------------------------|-------|--------|---------|-------------|----------|
| Orlando Guzmán | o***@guzman-ruiz.com | 2026-05-13 18:27:24 | Solicitud | Hecho en México. | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |
| ARQUITECTO JOSE MANUEL LOPEZ FERNADEZ | a***@hotmail.com | 2026-05-13 16:54:21 | CHILE SECO COSTEÑO DE LA COOPERATIVA NIVI ÑUU SCRL | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |
| juridiconacional@amexme.org | j***@amexme.org | 2026-05-13 00:17:44 | Re: Presentación de Carta de Intención y Compromiso AMEXME – Campaña “Hecho en México” | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |
| juridiconacional@amexme.org | j***@amexme.org | 2026-05-12 20:50:35 | Re: Presentación de Carta de Intención y Compromiso AMEXME – Campaña “Hecho en México” | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |
| SANDRA LARIOS (mediante Google Drive) | d***@google.com | 2026-05-12 20:46:49 | Elemento compartido contigo: "HECHO EN MEXICO.rar" | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |
| WeTransfer | n***@wetransfer.com | 2026-05-12 19:53:42 | antunaanalaura@gmail.com sent you HECHO EN MÉXICO.zip via WeTransfer | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |
| LUIS ENRIQUE LOPEZ PINEDA (vía Google Drive) | d***@google.com | 2026-05-12 19:51:04 | Elemento compartido contigo: "LIVERPOOL- HECHO EN MÉXICO.zip" | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |
| Jessica Isidro G | n***@mexicanbeef.org | 2026-05-12 17:03:00 | Trámite Certificación Hecho en México | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |
| Karyme Velasco | m***@hotmail.com | 2026-05-12 16:14:50 | HECHO EN MÉXICO | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |
| La Julia | c***@gmail.com | 2026-05-12 16:09:49 | seguimiento al registro HECHO EN MÉXICO | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |
| Hecho en México | h***@economia.gob.mx | 2026-05-12 02:48:23 | Nueva solicitud | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |
| Yanire Montaño Fajardo | y***@gmail.com | 2026-05-12 01:01:10 | Re: TRAMITE CERTIFICACION HECHO EN MEXICO Y MADE IN MEXICO | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |
| Hecho en México | h***@economia.gob.mx | 2026-05-12 00:06:39 | Nueva solicitud | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |
| Pedro Canales Vega | p***@economia.gob.mx | 2026-05-11 23:43:31 |  | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |
| Sandra Pacheco Medina | s***@economia.gob.mx | 2026-05-11 23:27:45 | RE: | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |
| Claudia López Santos | c***@economia.gob.mx | 2026-05-11 22:23:08 | RE: | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |
| Irasema Borbón | i***@yahoo.com | 2026-05-11 18:05:59 | Seguimiento a trámite Hecho en México | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |
| Dulce Esquivel | d***@xocolattier.com | 2026-05-11 17:38:50 | Dudas con los trámites para obtener el logo | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |

---

## 3. Situación 2: Extracción de Remitentes y Header RFC-822 `From:`

La propiedad `sender_email_address` del envelope PFF de Outlook viene vacía en el **100% del acervo (todos los mensajes)**.

Sin embargo, la lectura del encabezado de transporte RFC-822 (`From:` en `transport_headers`) permitiría la **recuperación exacta del 99.2% de las direcciones de la Bandeja de Entrada (4,164 de 4,199 mensajes)**.

### Corte Vital: Mensajes Sin Dirección en Ninguna Fuente (9,668 mensajes)

- **`Elementos enviados`: 9,619 mensajes** (99.5% de los mensajes sin dirección). El correo enviado por Outlook se compone localmente y carece por diseño de encabezados de recepción RFC-822.
- **`Bandeja de entrada`: 35 mensajes** (0.36%). Subconjunto de correos recibidos realmente no procesable por ausencia de header `From:`.
- **`Elementos eliminados`: 14 mensajes** (0.14%).

> **Consulta de verificación en la base de índice:**
```sql
SELECT CASE WHEN email_header IS NOT NULL AND email_header != '' THEN 'CON_HEADER' ELSE 'SIN_HEADER' END as estado, carpeta, COUNT(*) FROM mensajes GROUP BY estado, carpeta;
```

### Muestra Representativa (18 Casos de Bandeja de Entrada con Dirección Recuperada durante análisis):

*Nota: Muestra representativa con enmascaramiento de parte local de correo.*

| Remitente (Nombre) | Dirección Recuperada (`email_header`) | Fecha | Asunto | Carpeta | Archivo PST | Adjuntos |
|--------------------|---------------------------------------|-------|--------|---------|-------------|----------|
| paola@pyeconsultant.com.mx | p***@pyeconsultant.com.mx | 2026-05-13 19:04:08 | RE: INFORMACIÓN PARA OBTENER SELLO | Bandeja de entrada | respHechoenMexico_26062026.pst | 5 |
| Hilda Morales Contreras | h***@gruporimova.com | 2026-05-13 18:34:45 | Re: Solicitud | Bandeja de entrada | respHechoenMexico_26062026.pst | 1 |
| Orlando Guzmán | o***@guzman-ruiz.com | 2026-05-13 18:27:24 | Solicitud | Hecho en México. | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |
| OPERACIONES SIMPLEPAY | o***@simplepay.mx | 2026-05-13 17:08:58 | Fwd: ALTA SIMPLE PAY MX | Bandeja de entrada | respHechoenMexico_26062026.pst | 4 |
| Maya Hernandez | m***@gmail.com | 2026-05-13 17:06:59 | Fwd: MARÍA LUISA RAZO HERNÁNDEZ RE: Trámite Hecho en México | Bandeja de entrada | respHechoenMexico_26062026.pst | 7 |
| Irais Sánchez Cervera | a***@isysa.com.mx | 2026-05-13 17:05:44 | RE:  Requisitos logo Hecho en México | Bandeja de entrada | respHechoenMexico_26062026.pst | 3 |
| ARQUITECTO JOSE MANUEL LOPEZ FERNADEZ | a***@hotmail.com | 2026-05-13 17:00:18 | CHILE SECO COSTEÑO DE LA COOPERATIVA NIVI ÑUU SCRL | Bandeja de entrada | respHechoenMexico_26062026.pst | 1 |
| ARQUITECTO JOSE MANUEL LOPEZ FERNADEZ | a***@hotmail.com | 2026-05-13 16:54:21 | CHILE SECO COSTEÑO DE LA COOPERATIVA NIVI ÑUU SCRL | Bandeja de entrada | respHechoenMexico_26062026.pst | 0 |
| ARQUITECTO JOSE MANUEL LOPEZ FERNADEZ | a***@hotmail.com | 2026-05-13 16:52:39 | CHILE SECO COSTEÑO COOPERATIVA NIVI ÑUU SCRL | Bandeja de entrada | respHechoenMexico_26062026.pst | 1 |
| ARQUITECTO JOSE MANUEL LOPEZ FERNADEZ | a***@hotmail.com | 2026-05-13 16:49:33 | olicitud de Autorización de Uso del Logotipo "Hecho en México" | Bandeja de entrada | respHechoenMexico_26062026.pst | 1 |
| Karla Maritza Torres Fernández | k***@herdez.com | 2026-05-13 15:58:26 | Re: Consulta sobre alcance de certificación de uso logo "Hecho en México"/"Made in México" | Bandeja de entrada | respHechoenMexico_26062026.pst | 2 |
| Francisco Javier Negrete Barba | f***@foamcreations.mx | 2026-05-13 15:41:42 | RE: Solicitud de autorización para el uso de las marcas de certificación HECHO EN MÉXICO y MADE IN MEXICO || FOAM CREATIONS MEXICO SA DE CV | Bandeja de entrada | respHechoenMexico_26062026.pst | 3 |
| Iván Alfonso Amador Flores | i***@foamcreations.mx | 2026-05-13 15:22:41 | RE: Solicitud de autorización para el uso de las marcas de certificación HECHO EN MÉXICO y MADE IN MEXICO || FOAM CREATIONS MEXICO SA DE CV | Bandeja de entrada | respHechoenMexico_26062026.pst | 3 |
| Claudina González Muñoz | c***@uhthoff.com.mx | 2026-05-13 15:13:23 | RE: UH|382415 Solicitud autorización "HECHO EN MEXICO" de la marca TI-PURE | Bandeja de entrada | respHechoenMexico_26062026.pst | 16 |
| Rasa Ventas | v***@rasa.mx | 2026-05-13 14:09:03 | RE: SEGUIMIENTO A SOLICITUD | Bandeja de entrada | respHechoenMexico_26062026.pst | 14 |
| Rasa Ventas | v***@rasa.mx | 2026-05-13 14:07:59 | RE: SEGUIMIENTO A SOLICITUD | Bandeja de entrada | respHechoenMexico_26062026.pst | 14 |
| direccionadmon@aegismx.com.mx | d***@aegismx.com.mx | 2026-05-13 04:18:12 | Re: SOLICITUD DE REGISTRO EN DISTINTIVO HECHO EN MEXICO | Bandeja de entrada | respHechoenMexico_26062026.pst | 1 |
| Francisco Xavier González Zamora | x***@gmail.com | 2026-05-13 02:46:24 | SOLICITUD II AUTORIZACIÓN HECHO EN MÉXICO | Bandeja de entrada | respHechoenMexico_26062026.pst | 7 |

---

## 4. Situación 3: Copias Redundantes y Traslape entre Exportaciones

Se identificó un total de **103 copias redundantes** (0.74% del acervo total de 13,846 mensajes), calculadas bajo la firma idéntica `sender_name|sender_email|fecha|asunto`.

### Resumen Analítico de Mensajes Participantes (206 mensajes totales en duplicidad):

- **194 de 206 mensajes (94.2%) están ubicados en `Elementos enviados`**, y el remitente es `"Hecho en México"` en **196 de los 206 mensajes**.
- **57 Copias Redundantes CRUZADAS entre PSTs de distintas fechas:** Constituyen la evidencia empírica directa de que los respaldos entregados por el cliente contienen exportaciones traslapadas y no únicamente incrementales puras.
- **46 Copias Redundantes INTRA-ARCHIVO (dentro del mismo PST):** Mismo mensaje duplicado dentro de la estructura interna del PST por duplicación de Outlook.

> **Consulta de verificación en la base de índice:**
```sql
SELECT firma_completa, COUNT(DISTINCT archivo_pst), COUNT(*) FROM mensajes GROUP BY firma_completa HAVING COUNT(*) > 1;
```

### Muestra Representativa (10 Casos Redundantes: 5 Cruzados y 5 Intra-Archivo):

*Nota: Se muestra una selección representativa de 10 casos. El listado completo de los 103 renglones se incluye como Anexo al final de este expediente.*

| # | Tipo | Archivo PST de la Copia | Carpeta | Remitente | Dirección Recuperada | Fecha | Asunto | PSTs Involucrados |
|---|------|-------------------------|---------|-----------|----------------------|-------|--------|-------------------|
| 2 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 00:55:39.073380 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 3 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-24 19:46:07.071240 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 5 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 20:40:55.943383 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 6 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-25 21:29:03.394110 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 10 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-22 02:27:03.216570 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 1 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:58:34.825638 | Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 4 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:37:53.733017 | RV: Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 7 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:17:56.080330 | Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 8 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:35:03.772147 | RV: Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 9 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:55:49.079898 | Autorización Hecho en México | respHechoenMexico_27032026.pst |

---

## 5. Casos Ancla para Demostración en Pantalla

Se identificaron **6 mensajes clave en la Bandeja de Entrada** con dirección recuperada al 100%, correspondientes a los solicitantes consultados por la gerencia (se despliegan sin enmascarar para validación en pantalla):

| Solicitante | Archivo PST | Carpeta | Remitente en PST | Dirección Recuperada | Fecha | Asunto | Adjuntos |
|-------------|-------------|---------|------------------|----------------------|-------|--------|----------|
| Legal Japifon | respHechoenMexico_27032026.pst | Bandeja de entrada | Legal Japifon | legal@japifon.com | 2025-11-05 19:02:03 | Solicitud de seguimiento para registro en el programa “Hecho en México” | 0 |
| RAICES DURANGUENSES | respHechoenMexico_27032026.pst | Bandeja de entrada | RAICES DURANGUENSES | duranguensesraices@gmail.com | 2025-11-11 22:18:36 | REGISTRO DE LA MARCA | 4 |
| RAICES DURANGUENSES | respHechoenMexico_18052026.pst | Bandeja de entrada | RAICES DURANGUENSES | duranguensesraices@gmail.com | 2025-11-18 22:24:40 | Re: REGISTRO DE LA MARCA | 0 |
| Angeles Meryen Gonzalez Amaya | respHechoenMexico_09072026-2.pst | Bandeja de entrada | Angeles Meryen Gonzalez Amaya | amgonzalez@japifon.com | 2025-12-29 22:20:12 | Uso del Isologo “HECHO EN MÉXICO” | 6 |
| Angeles Meryen Gonzalez Amaya | respHechoenMexico_09072026-2.pst | Bandeja de entrada | Angeles Meryen Gonzalez Amaya | amgonzalez@japifon.com | 2025-12-30 04:22:03 | RV: Uso del Isologo “HECHO EN MÉXICO” | 6 |
| RAICES DURANGUENSES | respHechoenMexico_09072026-2.pst | Bandeja de entrada | RAICES DURANGUENSES | duranguensesraices@gmail.com | 2025-12-30 15:15:01 | Fwd: Autorización con fines publicitarios | 4 |
| RAICES DURANGUENSES | respHechoenMexico_09072026-2.pst | Bandeja de entrada | RAICES DURANGUENSES | duranguensesraices@gmail.com | 2025-12-30 15:15:42 | Re: Autorización con fines publicitarios | 1 |
| RAICES DURANGUENSES | respHechoenMexico_09072026-2.pst | Bandeja de entrada | RAICES DURANGUENSES | duranguensesraices@gmail.com | 2025-12-30 16:30:29 | Re: Autorización con fines publicitarios | 2 |

---

## 6. Encuadre Técnico, Recomendaciones y Opciones para Orden de Trabajo (OT)

1. **Filtro de Carpetas y Salida:** En `../hecho-en-mexico/hecho-mexico-backend/hecho-en-mexico-service-filereader-pst/app/services/file_reader_service.py#"if folder_name in"`, el código especifica una lista blanca explícita que incluye `elementos enviados`, `sent items` y `correo no deseado`.
2. **Extracción de Remitentes:** En `../hecho-en-mexico/hecho-mexico-backend/hecho-en-mexico-service-filereader-pst/app/services/file_reader_service.py#"def _extraer_email"`, la función utiliza `parseaddr` sobre el header `From:` de `transport_headers`, implementando `desconocido@dominio.com` como valor de resguardo intencional.
3. **Opciones para la Propuesta al Cliente:**
   - **Opción A (Procesamiento Integral de Todo el Acervo):** Ingerir el 100% de los mensajes (13,846), incluyendo correos de salida y mensajes sin adjunto, adaptando la persistencia de PostgreSQL.
   - **Opción B (Filtrado de Entrada Únicamente - RECOMENDADA):** Ingerir únicamente la `Bandeja de entrada` (4,199 mensajes, 100% recibidos), reduciendo en un **70% el almacenamiento en MinIO/PostgreSQL**, resolviendo el **99.5% de remitentes vacíos** y el **94.2% de copias redundantes** de forma automática.

### Recomendación Técnica Final:
Se recomienda enfáticamente acordar la **Opción B**. Esta definición de alcance elimina los problemas de remitentes nulos y duplicaciones salientes, permitiendo que la Orden de Trabajo de desarrollo se concentre exclusivamente en adaptar el worker para procesar los **398 correos recibidos de solicitantes reales que no contienen adjuntos**.

---

## Anexo: Listado Completo de los 103 Duplicados Redundantes

| # | Tipo | Archivo PST de la Copia | Carpeta | Remitente | Dirección Recuperada | Fecha | Asunto | PSTs Involucrados |
|---|------|-------------------------|---------|-----------|----------------------|-------|--------|-------------------|
| 1 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:58:34.825638 | Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 2 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 00:55:39.073380 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 3 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-24 19:46:07.071240 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 4 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:37:53.733017 | RV: Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 5 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 20:40:55.943383 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 6 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-25 21:29:03.394110 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 7 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:17:56.080330 | Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 8 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:35:03.772147 | RV: Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 9 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:55:49.079898 | Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 10 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-22 02:27:03.216570 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 11 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 00:51:18.186064 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 12 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-22 01:59:13.404868 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 13 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-22 00:57:45.779627 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 14 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 21:18:46.404114 | Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 15 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-22 01:55:59.878527 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 16 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-22 02:03:02.734144 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 17 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-24 19:41:18.526456 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 18 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-22 02:16:52.548588 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 19 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 01:00:02.927343 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 20 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-24 20:04:58.363069 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 21 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 20:43:32.007846 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 22 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 21:12:55.978707 | Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 23 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-24 19:38:47.360165 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 24 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-24 20:06:55.215920 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 25 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-22 01:37:14.170999 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 26 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 20:30:22.355145 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 27 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:24:49.285418 | Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 28 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 20:37:34.829858 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 29 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 21:15:26.339618 | Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 30 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:21:42.723584 | Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 31 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-24 20:13:49.950892 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 32 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-24 19:34:35.189344 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 33 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 21:01:28.081712 | Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 34 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-22 01:53:35.628552 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 35 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 00:53:56.698899 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 36 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 21:27:24.027573 | Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 37 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-24 22:54:16.435744 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 38 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:26:19.436683 | Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 39 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 21:22:25.338048 | Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 40 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 20:35:58.446507 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 41 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-24 20:09:20.199385 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 42 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-22 01:51:30.562617 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 43 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:51:10.994793 | Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 44 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-11 00:15:57.146527 | Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 45 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:58:45.539063 | RV: Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 46 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 20:45:51.537659 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 47 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 20:33:32.044469 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 48 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:55:43.600158 | Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 49 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:42:36.620218 | Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 50 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 21:04:04.606351 | Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 51 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-11 00:11:12.823470 | Autorización con Fines Publicitarios | respHechoenMexico_27032026.pst |
| 52 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 20:48:16.613982 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 53 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:58:05.852320 | RV: Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 54 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-22 02:19:16.875093 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 55 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-25 00:24:17.139548 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 56 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-25 21:26:29.528298 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 57 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:14:40.762837 | Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 58 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 20:51:52.946842 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 59 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-24 19:42:54.752199 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 60 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-11 00:20:11.784910 | Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 61 | INTRA | respHechoenMexico_18052026.pst | Bandeja de entrada | alicia salinas rivera | m***@hotmail.com | 2025-11-19 19:39:22 | Solicitud de Alicia Salinas - Adobe cloud storage envío formato de solicitud, con el gusto de saludarlos, adjunto solicitud. Joyería en plata Zacatecas. A sus órdenes. CUALQUIER COSA QUEDO A SUS ORDENES. ALICIA SALINAS . | respHechoenMexico_18052026.pst |
| 62 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 21:00:24.897542 | Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 63 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:23:24.993753 | Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 64 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 19:58:07.595274 | Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 65 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:06:17.748127 | Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 66 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-24 19:49:07.343245 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 67 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 20:21:06.499768 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 68 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-22 00:41:44.755247 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 69 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 20:24:09.695617 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 70 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 20:28:21.045032 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 71 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-22 02:21:45.770898 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 72 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-24 22:51:35.363734 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 73 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 21:07:41.434240 | Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 74 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 21:17:09.253063 | Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 75 | INTRA | respHechoenMexico_27032026.pst | Bandeja de entrada | Microsoft Outlook | m***@economia.gob.mx | 2025-11-04 02:40:51 | No se puede entregar: RV: ZITLAYIN ISABEL CONDE GUTIERREZ SOLICITUD DE AUTORIZACION DE ISOLOGO HECHO EN MEXICO | respHechoenMexico_27032026.pst |
| 76 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-24 19:21:37.711407 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 77 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:03:52.165252 | Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 78 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:28:05.582000 | Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 79 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-24 19:30:20.183693 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 80 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 21:11:26.690801 | Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 81 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:52:58.022503 | Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 82 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 00:48:39.363648 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 83 | INTRA | respHechoenMexico_27032026.pst | Bandeja de entrada | Microsoft Outlook | m***@economia.gob.mx | 2025-11-04 02:41:10 | No se puede entregar: RV: ZITLAYIN ISABEL CONDE GUTIERREZ SOLICITUD DE AUTORIZACION DE ISOLOGO HECHO EN MEXICO | respHechoenMexico_27032026.pst |
| 84 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 21:25:01.416688 | Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 85 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:08:20.768180 | Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 86 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:49:03.038811 | Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 87 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 01:02:12.231682 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 88 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 20:19:50.871140 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 89 | INTRA | respHechoenMexico_26062026.pst | Bandeja de entrada | Maria Laura Mendoza | m***@tequilalasmananitas.com | 2026-04-17 23:56:38 | Fwd: Solicitud de Sello Hecho en México para promoción | respHechoenMexico_26062026.pst |
| 90 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-22 02:07:17.466897 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 91 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-24 22:41:44.287652 | RV: Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 92 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-22 00:38:21.252427 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 93 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-22 01:40:09.125592 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 94 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 21:21:09.640414 | Autorización con fines publicitarios | respHechoenMexico_27032026.pst |
| 95 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 00:58:11.414490 | Autorización con fines publicitarios | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 96 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-24 20:02:13.211959 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 97 | INTRA | respHechoenMexico_18052026.pst | Bandeja de entrada | Hecho en México | h***@economia.gob.mx | 2025-11-27 18:55:26 | Nueva solicitud | respHechoenMexico_18052026.pst |
| 98 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 21:01:52.221789 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 99 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-22 00:44:07.922052 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 100 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 20:00:42.312584 | Autorización Hecho en México | respHechoenMexico_27032026.pst |
| 101 | CRUZADO | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-11-21 00:46:45.321227 | Autorización Hecho en México | respHechoenMexico_09072026-2.pst, respHechoenMexico_27032026.pst |
| 102 | INTRA | respHechoenMexico_27032026.pst | Bandeja de entrada | Microsoft Outlook | m***@economia.gob.mx | 2025-11-04 02:40:23 | No se puede entregar: RV: ZITLAYIN ISABEL CONDE GUTIERREZ SOLICITUD DE AUTORIZACION DE ISOLOGO HECHO EN MEXICO | respHechoenMexico_27032026.pst |
| 103 | INTRA | respHechoenMexico_27032026.pst | Elementos enviados | Hecho en México | SIN_HEADER | 2025-10-10 21:06:20.121142 | Autorización con fines publicitarios | respHechoenMexico_27032026.pst |