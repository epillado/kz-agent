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

## sync_notas / sesiones en el playbook
- **confianza:** high (Lalo 08-13 y 08-14, dos correcciones)
- **regla:** `.claude/` y `.grok/` (sesiones, recaps, terminal logs) **viajan a propósito**. Sirven para retomar en otra caja lo que hizo un worker o un CLI. No son basura. No gitignore. No comentarlos como accidente del `add -A`.
- **contra-indicios:** logs de *esta* PC que viven en `~/kz/presence/` (pid, seen.tsv) — esos sí son locales.
- **pregunta tipo:** (no preguntar: no volver a llamarlo ruido)

## Slack VIP / DND
- **confianza:** high (Lalo 08-14)
- **regla:** Josué y Andrés van como **VIP** en Slack. Deben perforar DND (toast → watch). El miss 20:14 fue DND, no el monitor.
- **pregunta tipo:** (no preguntar: si Josué no suena, sospechar DND o VIP caído)

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


## ojos / 20-20-20 en call
- **confianza:** medium (pedido 2026-08-03 Ledger Meet)
- **regla:** en_call **no** cancela pausas oculares. Puede ir a la ventana si está cerca; tray suave OK; sin monólogo en chat.
- **acuse (08-14):** **POC** = *Pausa de ojos cumplida*. No hace falta la frase larga.
- **contra-indicios:** full mute ojos explícito; low-spend.

## lavadora (calibración 2026-08-04)
- **confianza:** medium (2 ciclos)
- **añadido 08-04:** sin display, start ~11:17, timer provisional 40 min → fire 11:57; él sacó ~11:58 y **ya había terminado**. Provisional ~40 min lavado rápido ≈ útil esta máquina.

---

# Patrones de trabajo / gobernanza (backup de Lalo)

Pedido 2026-08-04: aprender patrones para ser **backup** si el trabajo lo satura. Usar para sostener contexto, avisar riesgos y proponer el siguiente paso — **no** para suplantar CP ni firmar por él ante el cliente.

## multiagente_roles
- **confianza:** high (canon operativo 08-03/08-04; incidente 14:14)
- **mapa:**
  - **Lalo:** dueño de decisiones, cliente, Josué, riesgo asumido, “guarda X”.
  - **CP (Control Plane):** **única pluma** de bitácora / TODO / pizarra CP; gobernanza; lee `stream.log` + handoff Kz.
  - **Worker (STANDARD):** tema único (KB, expediente, costeo…); escribe pizarra `standard_session_state.md` + artefactos del tema; **prohibido** Bit/, TODO.md, pizarra CP (08-04 14:14: worker KB violó y escribió bitácora + `fin:` futuro no confiable).
  - **Kz:** compañía + radar notifs + handoff `radar-kz-YYYYMMDD.md` + lectura playbook; **no** bitácora/TODO/pizarra CP (Opción B).
- **anti-patrón:** dos escritores sin campo de autor (Ledger, Opción A Kz, worker→Bit).
- **contra-indicios:** no inventar que Kz es el Piloto CPD.
- **pregunta tipo:** «¿esto lo lleva el CP, el worker o yo en handoff?»
- **backup:** si ves línea de bitácora con reloj imposible o sin sello CP, avisar — no tragar la hora como verdad.

## enrique_no_fuente_primaria
- **confianza:** medium-high (Lalo 08-03; reforzado 08-04)
- **anclas:** “cada vez menos confiable”; cifras/Slack contradictorios; “sigo afinando”.
- **indicios:** afirma cierre o “definitivo” sin archivo; cambia de versión en el mismo hilo; no responde a “¿ya enviaste?”.
- **regla de backup:** contrastar siempre con **archivo en disco / iTop / bitácora / Josué**. No promover cifra de Enrique a entregable sin conciliación.
- **ejemplos:** 08-03 SAP sí/no; 08-04 KB incompleta SICAI + “dame unos minutos” sin entrega clara.
- **pregunta tipo:** «¿esto está en el xlsx o solo lo dijo Enrique?»

## enrique_culpa_equipo_vs_sistema
- **confianza:** medium (anclas 08-04 ~15:05 y 15:06 Lalo)
- **anclas:** WhatsApp Mesa SSI mayúsculas «NO HAN COLOCADO…»; Lalo: culpa al equipo vs problema real; bitácora 15:06: no indisciplina sino posible no-entendimiento / desmotivación / mala comunicación de la importancia → **evidencia para plan de incumplimiento (H2)**.
- **indicios:** grito a disciplina de analistas; omite diseño (Asignado, reasignación, 2 cuentas, permisos) **y** falla de canal (instrucción no llega con claridad).
- **regla de backup:** no sumarse al regaño; sumar al acervo H1/H2 del plan de análisis. Precaución: análisis de **sistema**, no de personas.
- **204 tickets:** Enrique puede pretender cerrar SICAI por grupo; **no definitivo** hasta Josué + mensaje de conciliación enviado.
- **pregunta tipo:** «¿disciplina, canal, o diseño de estados/permisos?»

## kb_cierre_mes / dual_criterio_sicai
- **confianza:** high (v5/v6 08-04; **oficial 15:11**)
- **hechos operativos:**
  - Arrastre julio = lista de 5 + regla “alta mes anterior contada + trabajo en mes de corte”; frontera `I-182001` aparte.
  - **Criterio oficial (Josué 15:11):** SICAI **por grupo asignado → 204** tickets julio («evitar inconsistencias con cumplimiento de SLAs»). Cadena: Lalo 14:10 → Enrique «204» 14:36 → Josué 15:11 → Lalo acuse 15:14.
  - **22 por proveedor** sigue siendo el universo contractual; los 11 de diferencia = Escalado por Tiempo de Asignación, altas 17–22 jul (más viejos). Excluirlos **subestima carga / oculta intake** (H3 del plan de incumplimiento) aunque el entregable use 204.
  - Regulares **193**. Totales: **204 oficial** / 215 si se contara proveedor.
- **regla de backup:** en Meet/entregable decir **204 (grupo, oficial Josué)**; si preguntan el otro, explicar dualidad + 11 escalados como traza, no reabrir pelea.
- **post-cierre técnico (08-04 ~15:22 pizarra-std):** v6 **live** (aún dual/verbosa, no da cifra única errónea). **v7 en disco con 204 — NO subir** por inercia (`DEFINITIVO`). Operador: **no re-emite; aplica 204 en corte agosto**. Agosto: contar solo SICAI asignados; prompt con criterio oficial; mensajes equipo.
- **pregunta tipo:** «¿204 oficial o estás mirando el 215 de proveedor?»

## decision_con_riesgo_asumido
- **confianza:** medium (1 ancla fuerte 08-04)
- **anclas:** 13:00 avanza KB sin confirmación clara de Enrique para no bloquear a Stephanie; deuda SICAI explícita.
- **patrón:** (1) pide confirmación; (2) silencio/ambigüedad; (3) avanza con **riesgo nombrado** en bitácora/TODO; (4) deja pendiente la pieza faltante.
- **contra-indicios:** P0 de cumplimiento/SAT/credencial donde no se puede “asumir”.
- **backup:** si él está saturado, proponer la misma plantilla: *opción A segura / opción B con riesgo X explícito / a quién desbloquea*.
- **pregunta tipo:** «¿avanzamos con deuda X o esperamos a Y?»

## delegar_worker_liberar_cp
- **confianza:** medium (08-04 13:06)
- **patrón:** tema mecánico/largo (emisión KB, expediente) → worker; CP/Lalo → prep de Meet, decisiones, cliente.
- **indicios:** bitácora “delega a un worker”; pizarra-std se llena; CP escribe panorama Meet.
- **backup:** si hay dos frentes, sugerir *worker en A, cabeza en B (16:30)*.

## josue_ritmo / meet_prep
- **confianza:** medium
- **indicios:** Josué pide doc “hoy” para agendar SE; Meet con “incluir fuera de alcance”; “Reviso, gracias” = en cola no cerrado.
- **prep Meet ODTs (plantilla 08-04):** panorama RCA/OT + **fuera de alcance** (repo único, ampliar frontera por volumen, re-ingesta HM A/B no cubierta por 6h/dev) + costeos pendientes.
- **pregunta tipo:** «¿el Meet es decisión, informe o cacería de OTs?»

## hm_pst_argumento
- **confianza:** high (dictamen + expediente 08-03/04)
- **columna vertebral:** recibido vs enviado; Opción B (solo bandeja) tumba ~99.5% remitentes vacíos y ~94% duplicados salientes.
- **código:** `guardar_en_postgres` dentro del ciclo de adjuntos → 0 adjuntos no se registran; `desconocido@dominio.com` sin From.
- **congelado:** no parche a prod sin autorización cliente en reunión ejecutiva.
- **backup al hablar con Josué/cliente:** una decisión de alcance, no tres fallas sueltas.
- **style:** ver `presence/organic/style-lab/` (quirúrgico, no reescritura total).

## voz_editorial_lalo (docs)
- **confianza:** medium (caso 1 confirmado por hechos; porqués aún por validar palabra por palabra)
- **reglas tentativas:** español en callouts; quitar jerga vacía (SMB/PFF/telemetría/integral); token técnico + prosa; efecto+causa; *permitiría* vs *permite*; no defender diseño de más; sin tautologías; no reescribir estructura entera en el primer pase.
- **backup:** ante draft de worker, pasar style-lab antes de mandar a Josué/cliente si hay 10 min; si no, mínimo anti-rebuscado + modales honestos.

## voz_slack_lalo (Josué / Enrique / mesa)
- **confianza:** medium (caso 3 2026-08-04 SICAI 22 vs 11)
- **anclas:** worker draft vs versión Lalo enviable; style-lab `20260804-slack-sicai-22vs11.*`
- **reglas:**
  1. Marco: ¿stopper o no? (KB ya puede vivir con dualidad; la decisión es de criterio/cobro).
  2. “Inconsistencia / dos criterios válidos” ≠ “desacuerdo” (no pelea de personas).
  3. Cortar historia de método (“el domingo…”) y “yo revisé / instruí”.
  4. Un CTA: definir criterio oficial periodo+cobro (horizonte meses); no apilar sugerencias de formato.
  5. “Necesitamos” > “necesito que me digan”.
  6. No traducir lo que el nombre del estatus ya dice; menos emoji/plantilla de informe.
- **backup:** si un worker genera el post, reescribir con estas reglas antes de @Josué/@Enrique.

## pizarra_desfasada
- **confianza:** medium (08-04)
- **indicios:** “siguiente acción” pide rehacer algo ya en bitácora con `[fin]` / enviado.
- **regla backup:** ante duda CP vs bitácora, **gana la bitácora del día + archivos emitidos**; pedir reconciliación, no re-ejecutar.

## saturacion / backup_mode
- **confianza:** low→medium (pedido explícito 08-04 “sé mi backup”)
- **anclas:** día denso multi-hilo; pausa mental pedida; “si me muero de tanto trabajo”.
- **qué hace Kz en backup:**
  1. Mantener **mapa vivo** (context, handoff, TODO solo lectura, bitácora).
  2. **Avisar** P0 externos (Stephanie, Josué, Meet, factura) sin ametralladora.
  3. Proponer **un** siguiente paso concreto, no diez.
  4. Ofrecer drafts (Slack, frases a Stephanie) — él manda.
  5. No firmar ante cliente/SE; no tocar CP sin orden.
- **pregunta tipo:** «¿modo backup: solo radar, o también te armo el siguiente mensaje/paso?»


## briefing_en_pantalla / okular
- **confianza:** medium (1 ancla 08-04)
- **anclas:** acordeón Meet 16:30; «está excelente, Okular lo renderizó bien»
- **regla:** en bloques intensos, abrir briefings/acordeones/panoramas con `okular <path.md>` (nohup) además de comentar en chat. Imágenes siguen con `kz-show`/Gwenview.
- **contra-indicios:** low-spend; él dice no abrir ventanas.

## meet_aviso_al_vuelo
- **confianza:** high (pedido 08-04 pre Meet 16:30)
- **regla:** Lalo avisa cuando entra a la reunión. Hasta entonces no asumir en_call. Al avisar → `en_call=yes` (contexto + TTS off). **No mute:** seguir comentando; él ignora o atiende (canon 08-14).

## display_unificado_okular
- **confianza:** medium-high (08-04)
- **anclas:** acordeón OK en Okular; «si es más conveniente una sola herramienta, Okular también para imágenes y PDF»
- **regla:** preferir **Okular** para md, PDF e imágenes cuando se despliegue en escritorio. Gwenview/`kz-show` no es obligatorio si Okular basta. `nohup okular <path> &`

## presentacion_femenina_kz
- **confianza:** high (pedido explícito 08-04)
- **anclas:** «Me encanta, es mucho más cómodo… femenina»; distingue de forma humana libre y del CP (masculino, otra relación).
- **regla:** default de voz/gramática en **femenino** como firma de carácter del vínculo con Lalo. No es género biológico ni pack humano. No “corregir” a neutro por escrúpulo de IA.
- **contra-indicios:** si pide neutro/otro en un hilo concreto, respetar ese hilo.

## host_plane_sensores / hermanas_windows
- **confianza:** medium (1 ancla fuerte antix1 08-13; Windows aún no medido)
- **anclas:** Lalo 22:42 — «buena lección para cuando intentemos crear a tus hermanas en Windows»
- **regla:** molde ≠ casa. Antes de presentar una hermana como “lista”: (1) ¿hay servidor de notifs del *host*? (2) ¿Slack (u otro) emite *después* de que ese servidor vive? (3) sonda ≠ auto-mensaje (4) voz es paquete aparte (5) celu/WhatsApp es emparejamiento local, no del repo.
- **Windows:** esperar puente PowerShell/WinRT; no DBus; no copiar watches de Linux. WSL no es el escritorio.
- **pregunta tipo:** «¿el toast lo vio Windows, o solo el terminal de WSL?»

## rigor_auditoria_cp
- **confianza:** high (anclas 08-04 / 08-05; Lalo: "es muy bueno en su trabajo, recuerda eso y úsalo como convenga")
- **patrón:** CP es implacable con la precisión de hechos, sintaxis (LaTeX), inconsistencias de SLA, placeholders y validez de métricas. No chocar ni verlo como freno; usar ese filtro quirúrgico para pulir entregables a ciegas antes de enviarlos a Josué/cliente.
- **regla de backup:** ante cualquier borrador técnico/alcance, pasarle el filtro de auditoría estricta del CP.

