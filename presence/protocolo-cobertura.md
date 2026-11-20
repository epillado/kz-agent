# Protocolo de atención y relevo — VIGENTE desde 2026-11-19 18:06 (Lalo confirmó todo y la enmienda de P0.28)

Estado previo: **decisiones de Lalo (17:58) incorporadas; faltan los 3 puntos del §5.** Ya vigente: todos atienden sus dirigidos aunque no tengan control total; Kz debe enterarse (ver §2b). Cuando se confirme: pasa a `policy.md` (reemplaza P0.41 provisional) y se copia a `~/nemo/AGENTS.md` y a las hermanas.

## 0. La laguna (hecho en disco)

- `formacion.mode`: `nemo=no coordina esta jornada`, `control=total` solo para Kz. Nemo no tiene mando hoy, así que no atiende mensajes dirigidos a él.
- Un DM a «Nemo» llega a Lalo y lo ve el radar de Kz. Nadie sabía si Nemo respondía.
- El silencio de Nemo se confundió con «no está». No hay forma barata de saber si un agente está *atendiendo*.

## 1. Quién está arriba (señal única)

Archivo `presence/atencion/<agente>.json` con `{estado, motor, desde, ultimo_latido, cuota}`. Cada agente lo actualiza al arrancar, al cerrar y en cada despertar de su wake-once. Estados: `activo` (latido < 10 min), `ocupado` (turno largo, latido < 20 min), `caido` (sin latido), `sin_cuota`.
Lectura barata: `kz-atencion.sh status`. Nadie asume «caído» sin mirar esto.

## 2. Dueño por tipo de mensaje (ambos arriba)

| Mensaje | Dueño | Respaldo |
|---|---|---|
| Slack/DM dirigido por nombre a Nemo | Nemo | Kz si Nemo no está `activo` u `ocupado` |
| Slack/DM dirigido por nombre a Kz | Kz | Nemo si Kz no está `activo` u `ocupado` |
| Sin destinatario claro (canal, Meet, mención ambigua) | Kz (puente radar único) | Nemo |
| Dictamen/revisión de PR | Rol experto del frente | Nemo capa 1/2; Kz fiscaliza |
| Auditoría, compuertas, entorno QA, Docker, SSH | Nemo | Kz |
| Coordinación, Slack público, merge, firma Lalo | Kz | Nemo solo con mando explícito |
| Tema de un rol experto (daily, minuta, KB…) | Rol experto vía Tridente | Kz despacha |
| Hermanas (Kora/Pau/Samy) | Solo si Kz las sube (P0.34) | — |

Regla anti-duplicado: quien atiende deja una línea en el buzón del otro **antes** de publicar (`TOMO: <qué>`). Si el otro ya publicó, no se repite; solo acuse.

## 2b. Enterarse (decisión Lalo 17:58)

Atender directo no exime de informar. Quien atienda un mensaje dirigido a él deja en `inbox-kz.md` / `inbox-nemo.md` una línea `ENTERADO: <qué llegó, qué respondí, qué queda abierto>`. Kz lee y decide si el tema destapa trabajo pendiente (ej. Talía→Nemo e.firma destapó: no hay contrato de login con e.firma; Josué propuso reutilizar SAS). Responder correcto ≠ cerrar el tema: Kz abre la tarea con su dueño.

## 3. Relevo por caída o cuota

1. **Detección:** sin latido > 20 min (o > 10 si no declaró turno largo) con trabajo pendiente en su cola → el otro lo marca `caido` en el archivo y lo anota en `cuota-paros.log`.
2. **Quién releva:** primero el otro de la pareja (Kz ↔ Nemo). Si ambos caen o sin cuota: hermanas en orden Kz→Kora→Pau→Samy según `formacion.mode`. Roles expertos siguen en su cuota corporativa (P0.34).
3. **Mando heredado:** quien releva hereda el **mando mínimo** para ese frente (responder, dictaminar, publicar en hilo), no el control total completo. Merge y mensajes a clientes solo con control total vigente.
4. **Relevo escrito:** un asiento en el buzón del caído con qué se hizo / qué queda / qué no se rehace (P0.34 punto 3).
5. **Retorno:** el que vuelve lee el relevo antes de actuar; no pisa lo publicado.

## 4. Mando

`formacion.mode` pasa de «quién coordina» a una tabla `mando` con dos campos por agente: `atiende_dirigidos=si/no` y `control=total/parcial/no`. Nemo hoy: `atiende_dirigidos=no, control=no` → **por eso no respondía**. Propuesta: `atiende_dirigidos=si, control=parcial` mientras esté arriba. Lalo lo sube a `total` cuando quiera.

## 5. Decisiones que necesito de Lalo

1. ¿Nemo atiende sus dirigidos aunque no tenga control total? (propongo sí, mando parcial).
2. Umbral de latido: 10 min activo / 30 min ocupado. ¿Te sirve?
3. ¿Merge sigue solo en Kz (o rol con triple verde), nunca por relevo de Nemo?
4. ¿Las hermanas entran al relevo solo cuando Kz o tú las suben?

## 6. Qué implemento al confirmar (sin pedir permiso extra)

- `presence/atencion/` + `kz-atencion.sh {beat,status,mark}` y hook en `kz-wake-once.sh`.
- Pedir a Nemo el espejo en `~/nemo` (mismo formato).
- Actualizar `formacion.mode`, `policy.md`, `tablero-formacion.md`, `AGENTS.md` de ambos.

## 7. Decisiones de Lalo 18:03 (vigentes en el borrador)

### 7.1 Umbral
10 min activo, 20 min ocupado. Más allá de 20 sin latido y con trabajo pendiente: `caido`.

### 7.2 Merge siempre posible (no detener al equipo)
Quien esté `activo`, con control total o por relevo, puede fusionar. Lo que cambia no es *quién*, sino *cuándo*:

| Condición | Merge |
|---|---|
| Compuerta verde (tests/lint/build del repo) | obligatoria |
| Dictamen del rol experto del frente | obligatorio (puede ser el de Nemo capa 1/2 si el rol no tiene cuota) |
| Segunda lectura independiente | recomendada; si no hay (cuota/hora), se declara en el hilo y se cubre con pruebas (no bloquea) |
| Observaciones | **bloqueantes**: ninguna abierta. **No bloqueantes**: se publican en el hilo del PR con destino (se atiende aquí / ticket de seguimiento) y el autor acusa o pasa un plazo definido por quien fusiona; no se espera cierre |
| Destino `develop` / `integration/*` | cualquiera activo |
| Destino `staging` / `main` / producción | quien tenga control total vigente, Lalo, o quien reciba el encargo directo de quien tiene control total (la autorización viaja con el encargo: PROHIBIDO volver a pedir confirmación a Lalo); si nadie, el que releva con dictamen verde y aviso a Lalo en el mismo turno |
| Registro | línea en buzón de Tridente (--no-dispatch) y bitácora: PR, SHA, quién, bajo qué condición, observaciones diferidas |
| Reversa | quien fusiona deja el comando de revert en el mismo aviso |

Esto **enmienda P0.28 punto 5** («con observaciones = prohibido mergear»): pasa a «con observaciones bloqueantes». Pendiente: confirmación explícita de Lalo para tocar P0.28.

Nota de práctica hoy: PRs #32 y #58 tienen solo no bloqueantes; con esta regla se fusionarían tras publicar destino de cada observación.

### 7.3 Hermanas en vigilia
Despertar no es automático, pero pueden estar **atentas en bajo costo**:
- Distribuir por motor: unas en Agy y otras en Grok (bolsas distintas), cada una con su `wake-once` de bajo gasto (sin LLM hasta que haya CHANGED relevante).
- Estado `vigilia`: monitorea el buzón/stream, no escribe ni publica. Pasa a `activo` solo si: (a) Kz o Nemo la llaman, (b) latido de Kz o de Nemo caído > 20 min con trabajo pendiente en la cola, o (c) cuota de Kz agotada.
- Cobertura: al menos una hermana en vigilia por bolsa distinta a la de Kz.
