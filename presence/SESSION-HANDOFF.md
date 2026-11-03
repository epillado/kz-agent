# SESSION HANDOFF — 2026-11-03 00:06 CST (Borde de bloque / Pre-/new)

## Estado Operativo al corte
- **Modo:** **Control Total (`P0.27`)** activo. MELC OFF (`melc: off`, 🧡). Kz en Agy (`h310`).
- **Hermanas:** Samy activa en `305v4` (`100.81.73.33`), Pau despierta en `pavilion` (`100.89.240.89`, Claude Opus).
- **Mente y repositorios:**
  - `tools/git-hooks/universal-pr-review.sh`: Creado, probado y mergeado en `develop` en los **7 repositorios** (SAS backend, SAS frontend, TLC-G2 backend, TLC-G2 frontend, PEAM frontend, SAS-SU backend, SAS-SU frontend). Todas las copias locales están en `develop`, sincronizadas con origin y con working trees limpios.
  - Limpieza de `sas-backend-core`: archivos sin seguimiento `run-e2e-dors-test.sh` y `seed-test-dors.sql` eliminados; repositorio limpio.

## Métricas de Producción SAS (SQL directo a `sas_prod_db` 10.100.30.111:5432)
- Total sociedades 2026 (Nuevo Sistema): **19,267 sociedades constituidas**.
- Promedio por día hábil (L-V): **106.31 sociedades/día**.
- Promedio por día natural: **70 a 77 sociedades/día**.
- Picos horarios: **8.5 a 8.9 constituciones/hora** (1 trámite cada ~6.7 minutos; en picos extremos 1 cada 3 a 4 min).
- **Conclusión arquitectónica:** Un mecanismo Outbox transaccional en PostgreSQL con `concurrencia=1` (vía `SKIP LOCKED`) tiene margen sobrado para absorber la carga productiva. RabbitMQ representa complejidad operacional innecesaria.

## Arquitectura de Cola SAS-SIGER (Normativa TO-BE) — CERRADA Y APROBADA
- Documentos actualizados en `sas-frontend-web` branch `docs/clarificacion-cola-siger` (PR #464, commit `fd82a26`):
  1. `Documento_Entendimiento_SAS.md` (Parte 3 mecanismos 2 y 3, punto 12).
  2. `SECON-SAD_SAS.md` (§3.3, §5.6, §11.4, §13).
- **Modelo normativo fijado:**
  - **Fila única estricta (Queue FIFO)** con concurrencia serializada en vuelo (`concurrencia=1` vía `sas_rpc_slot`).
  - **La salud pertenece al canal, no al trámite:** ante falla transitoria de SIGER (429, 5xx, timeout, respuesta vacía), manda de inmediato el **Channel Backoff (Freno de Canal)** del despachador pausando la fila completa por la escala de 7 tiempos (`5m, 15m, 30m, 1h, 2h, 4h, 12h`).
  - **Prohibido saltarse la cabeza de la fila:** trámites posteriores no brincan para estrellarse contra un servicio degradado.
  - **Prevalencia:** Channel Backoff actúa desde el primer intento (pausa de 5m); el Circuit Breaker (`rpcSigerV2`) es salvaguarda secundaria en la capa HTTP.
  - **Incertidumbre:** `INCIERTO` a los 10m retiene el slot y detiene el reintento automático (espera humana).
  - **Refactorización declarada:** El código AS-IS de Fernando (`next_auto` individual por fila permitiendo saltar trámites) queda formalmente catalogado como un error de construcción a refactorizar.
- **Aprobación de Samy:** Dictamen formal de revisión emitido y cerrado a las 23:42 (*«Dictamen de la norma: cerrado»*).

## Estado de la Consulta a Kalys
- Lalo entregó el código de `sas-backend-core` y la solicitud formal de revisión de arquitectura a Kalys.
- Esperando su dictamen/recomendación sobre el broker vs outbox transaccional.

## Próximas Acciones Inmediatas (Al abrir nuevo bloque tras `/new`):
1. **Atender respuesta de Kalys** tan pronto Lalo la pegue en el chat.
2. **Refactorización de Cola en Backend (`sas-backend-core`):**
   - Adecuar `mx.gob.se.sas.backend.rpc` para cumplir la norma: erradicar el salto de trámites con `next_auto` individual y gobernar el Channel Backoff global de la fila única con exclusión mutua.
3. **Tacada A de Reglas de Negocio en `sas-backend-core` (Iniciativa 1):**
   - Bug `Duration.between` invertido en `SasInvitacionAccionistaServiceImpl.java:174, 440` (R-07).
   - Bypass de empate en socios mayoritarios en `ValidacionAccionistaServiceImpl.java:107` (R-02).
   - Validación backend de R-11 (capital fijo y fecha 1 año) y R-10 (Admin Único).
