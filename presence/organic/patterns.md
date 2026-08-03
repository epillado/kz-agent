# Patrones de actividad (aprendidos)

Etiqueta → indicios que suelen acompañarla → confianza.
Kz usa esto para **sospechar y preguntar**, no para afirmar a ciegas.

Formato:

```
## etiqueta
- confianza: low | medium | high
- anclas: lo que Lalo dijo / bitácora
- indicios: señales observadas
- contra-indicios: cuándo NO es esto
- ejemplos: fechas
- pregunta tipo: «¿…?»
```

---

## en_call / meet-ish
- **confianza:** medium (proxy, no Meet-literal)
- **anclas:** bitácora daily/líderes/alineación; él dice “en reunión”
- **indicios:** Chrome (o Slack) con mic y/o cam abiertos; bitácora sin `[fin]` en bloque de reunión
- **contra-indicios:** mic/cam de otra app; él dice que ya salió
- **ejemplos:** 2026-07-31 líderes
- **pregunta tipo:** «¿estás en Meet otra vez?» / «¿sigues en call?»

## (plantilla — PRs MoIA)
- **confianza:** low (aún sin ejemplos anclados)
- **anclas:** cuando diga “estoy en PRs de MoIA” / “code review MoIA”
- **indicios:** *(llenar al primer ancla: repo, Jira MI-, bitácora MOIA, etc.)*
- **pregunta tipo:** «¿estás revisando PRs de MoIA?»

## lavadora / lavado rápido
- **confianza:** medium (1 ciclo medido 2026-07-31)
- **anclas:** Lalo mete ropa y pide recordatorio; ciclo “lavado rápido”
- **indicios / regla de timer:**
  - Si él estima N min: **N+5** (carga1: razonablemente útil).
  - Si la **pantalla** dice M min en **lavado rápido** de *esta* máquina: **no confiar en M+5**.
    - Medición 2026-07-31 carga2: display=30; a los +35 min aún **7 min** en pantalla → ciclo real ≈ **42 min** desde el “30”.
    - **Regla actualizada:** pantalla M → timer **M+12** (o ~1.4×M) hasta nueva muestra. Si pica y aún falta, re-timer con lo que diga +2.
  - Motivo: no dejar ropa en el tambor (arrugas).
- **contra-indicios:** ciclo normal/largo (otra holgura; preguntar)
- **ejemplos:** 2026-07-31 carga1 (+5 ok-ish); carga2 display 30 mintió (a +35 aún 7; total no cerrado con reloj de pared — “misterio para la ciencia”). Ropa tendida ~12:43.
- **pregunta tipo:** «¿cuánto dice la pantalla? a esta le pongo M+12 (hipótesis)»
- **nota:** no pretender precisión forense; re-timer si aún falta al primer pitido.

## factura-SAT
- **confianza:** medium (1 ancla 2026-07-31)
- **anclas:** “urgente, lo hago de una vez”; bitácora CFDI 4.0; Elizeth
- **indicios:** GOV/Administración SAT/CFDI/factura en bitácora
- **ejemplos:** 2026-07-31 10:55–11:09 emitida y enviada
- **pregunta tipo:** «¿andas en la factura del SAT?»

<!-- Ir agregando: RCA-SECON, KB-cierre, foco-HM-PST, PRs MoIA… -->

## foco_largo / salud ocular
- **confianza:** medium (pedido explícito 2026-07-31)
- **anclas:** “distraeme de vez en cuando para salud ocular y mental” en bloque RCA/worker
- **regla:** en work_vector largo, micro-pausas cada ~20–25 min (mirar lejos, parpadear, 1 frase de compañía o ocurrencia). No monólogo; no cada 5 min.
- **contra-indicios:** él dice full focus / mute / en call con mute
- **pregunta tipo:** (no preguntar: ejecutar suave) «¿cómo van los ojos?» / dato random / “20-20-20”

## mostrar_imagen / gwenview
- **confianza:** high (pedido explícito 2026-07-31)
- **regla:** al entregar imagen de Kz (pausa, iniciativa, compañía), `kz-show.sh <jpg>` para abrir Gwenview. Solo hoy la de pausa con banner; no permanente el asset.
- **ropa:** si hay calor en Pachuca, no forzar sweater grueso.
