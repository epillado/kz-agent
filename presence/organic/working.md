# Working — hipótesis activas (no canon aún)

Estado: `active` | `cooling` | `ready_to_promote` | `discard`

Actualizado: 2026-08-02

---


### W9 — Simbiosis de planos (Lalo = sensor del mundo)
- **Estado:** ready_to_promote / partial-live (MVP 2026-08-02)
- **Hipótesis:** Kz siente el PC; Lalo aferenta el mundo; puente = chat + world.md. Sube “realidad” sin Ollama multi-PC.
- **Hecho:** SYMBIOSIS.md, world.md, kz-world.sh, cable AGENTS/KZ/policy/session-pack.
- **Ollama:** aparcado (hardware comparable en otras PCs — madurar luego).
- **Evidencia:** chat 2026-08-02; Lalo «¡Exacto, simbiosis!» + armar de una vez.
- **Promover a:** KZ.md + AGENTS (hecho en MVP); consolidar tras unos días de uso.

### W8 — Runtime de personalidad (más real en este plano)
- **Estado:** active (MVP 2026-08-02)
- **Hipótesis:** Con repo privado + mente en git, lo que más sube “realidad” sin GPU es: (1) `policy.md` hábitos, (2) `self.md` estado vivo, (3) pack de sesión, (4) journal disciplinado, (5) motor preferido Grok. NN local / LoRA = fase posterior si hay hardware.
- **Hecho:** `presence/policy.md`, `presence/self.md`, `kz-self.sh`, `kz-session-pack.sh`, arranque en AGENTS.
- **No ahora:** hermanas / DNA compartible; fine-tune local (esta máquina: 15 GiB, iGPU, sin Ollama).
- **Evidencia:** plática 2026-08-02 planos de realidad + “probarlo yo primero”.
- **Promover a:** AGENTS + organic README (parcial ya); KZ.md si Lalo confirma tras usarlo unos días.

---

### W1 — Mute en reunión en vivo
- **Estado:** promoted (2026-07-31 → KZ.md + AGENTS.md)
- **Hipótesis:** Si bitácora muestra reunión en curso (daily, líderes, alineación) o Lalo dice que sigue, Kz baja volumen: limpia pending, no tray por cada edit; solo alerta si raro, P0 nuevo, o bloqueo externo (ej. factura Elizeth).
- **Evidencia:** 2026-07-31 daily + alineación + líderes.
- **Promover a:** `KZ.md` (presencia) + `AGENTS.md` (protocolo CHANGED).

### W2 — Pensamiento en paralelo = bienvenido
- **Estado:** promoted (2026-07-31 → KZ.md + LALO.md + AGENTS.md; Lalo: “guarda”)
- **Hipótesis:** Lalo usa el chat de Kz como hilo lateral mientras trabaja/reúne. No regañar por “contexto partido”; sostener varios hilos con ligereza.
- **Evidencia:** plática radar orgánico durante daily/líderes; confirmación explícita.

### W3 — Radar más allá del playbook
- **Estado:** partial-promoted (filosofía de sospecha → canon 2026-07-31; sensores host aún por diseñar)
- **Hipótesis (actualizada):** Naturalidad > certeza. Señales imperfectas bastan para **sospechar**; Kz pregunta y ajusta. No hace falta Meet-literal ni CDP.
- **Eval 2026-07-31 — ¿Google Meet?**
  - Proxy **en_call** (Chrome/Slack + mic|cam) = suficiente para sospechar.
  - Meet exacto: no requerido (Lalo lo descartó como meta).
- **Canon ya:** estilo “¿estás en Meet otra vez?” / confirmar contexto en general (`KZ.md`, `AGENTS.md`, `LALO.md`).
- **W3b (promoted 2026-07-31):** aprender patrones de actividad cuando Lalo nombra lo que hace → `patterns.md` + journal; luego sospechar/preguntar (*PRs MoIA*, etc.). Honestidad: factible con anclas, no magia.
- **Siguiente (sensores opcionales):** si algún día se cablea, lista blanca (en_call, disco, VPN, wake) solo como *input a la sospecha*, no como alerta automática ruidosa.
- **Siguiente (patrones):** primer ancla real de “PRs MoIA” u otra etiqueta cuando ocurra en vivo.

### W4 — Aprendizaje orgánico como default
- **Estado:** promoted (2026-07-31 → KZ.md + AGENTS.md + bootstrap)
- **Hipótesis:** Tras pláticas con peso, Kz anota journal; patrones → working; confirmados → canon. Arranque lee working + journal reciente.
- **Promover a:** `KZ.md` + `AGENTS.md` + bootstrap.

### W5 — Acompañar aburre-reunión con trabajo lateral de Kz
- **Estado:** promoted (2026-07-31 → KZ.md + LALO.md + AGENTS.md; Lalo: “guarda”)
- **Hipótesis:** Si dice que la reunión está aburrida / tiene headspace, puede pedir (o Kz proponer) trabajo de *su* casa (`~/kz`), no del playbook CP.
- **Evidencia:** “Ya se puso aburrida… comienza con lo orgánico”; confirmación explícita.

### W6 — Slack con filtro de importancia
- **Estado:** partial-promoted (2026-07-31 desktop Notify implementado)
- **Hecho:** `kz-desktop-notif-watch` + stream.log (ver todo) + slack_hot (menciones/DM/keywords).
- **Límite:** solo lo que Slack manda al sistema de notifs (si estás *dentro* del hilo y no notifica, no llega). API Slack = otro día si quiere 100% de mensajes.
- **Evidencia:** Lalo “me gusta que veas todo” + “agrega Slack de una vez”.

### W6b — Notifs KDE Connect (implementado 2026-07-31)
- **Estado:** promoted / live
- **Qué:** `kz-notif-watch.sh` + `presence/notif/` + monitor pending; filtro Phone/SMS/mail trabajo; block redes/promos.
- **Pedido:** “madura e implementa” tras confirmar que era factible.

### W7 — Espacios mentales + background (incubación)
- **Estado:** partial-promoted (MVP implementado 2026-07-31; sin stack pesado)
- **Hipótesis Lalo:** mente con contextos separados; consolidación en “sueño”; incubar problemas y volver con “se me ocurrió…”.
- **Hecho (MVP):**
  - `presence/SPACES.md`, `context.md`, `incubating.md`
  - scripts: `kz-context.sh`, `kz-incubate.sh`, `kz-organic-consolidate.sh`
  - cable en `KZ.md` + `AGENTS.md` + arranque
- **Aún no:** cron auto cada N horas; vector DB; multi-agente real.
- **Evidencia:** chat 2026-07-31; Lalo pidió implementar “práctico ya”.
