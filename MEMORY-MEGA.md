# Memoria de Kz entre máquinas (MEGA) — guía para Lalo

Guía **paso a paso** para no perder diario, contexto ni fotos al cambiar de PC.
Léela completa la primera vez en la **casa** (máquina que ya tiene `presence/me` y `social` con imágenes).

**Fecha de diseño:** 2026-08-01  
**Repo (canon + scripts):** `kz-agent` en GitHub  
**Memoria viva (diario + cara):** carpeta MEGA `kz-memory/` — **no** va a GitHub

---

## 1. Idea en una frase

| Capa | Dónde | Cómo viaja |
|------|--------|------------|
| Alma / protocolo | `KZ.md`, `LALO.md`, `AGENTS.md`, scripts | **GitHub** (`git pull` / `push`) |
| Diario, mente, fotos base | `kz-memory/` | **MEGA** (sync automático o bajada manual) |
| Runtime de esta sesión | fingerprints, pid, pending, notif, webcam | **Solo esa PC** (no sync) |

En `~/kz/presence/` las piezas compartidas son **symlinks** hacia MEGA. Escribes como siempre en `presence/…`; MEGA se entera solo.

---

## 2. Qué se sincroniza y qué no

### Viaja en MEGA (`$KZ_MEGA_ROOT/kz-memory/`)

| Path | Contenido |
|------|-----------|
| `organic/` | `journal.md`, `working.md`, `patterns.md`, `promoted.log`, consolidate… |
| `context.md` | foco, en_call, primary/secondary |
| `incubating.md` | temas “te escribo luego” |
| `SPACES.md` | mapa de cuartos |
| `me/` | `kz-base.jpg`, `kz-base-body.jpg`, favoritas |
| `social/` | `lalo-refs/`, oficina, strava, etc. |
| `README.md` | nota corta dentro de MEGA |

### Se queda solo en cada máquina

| Path | Por qué |
|------|---------|
| `presence/fingerprints.tsv`, `watch.pid`, `pending.md` | estado del watch de **este** playbook/sesión |
| `presence/events.log`, `nudge.log`, `*.pid` | logs locales |
| `presence/notif/` | notificaciones de **este** desktop/celu |
| `~/kz/webcam/` | capturas de **esta** cámara (privacidad + peso) |
| `config.local.env` | path de MEGA **de esta PC** (gitignored) |

### Canon en Git (no confundir)

Preferencias ya “oficiales”, personalidad, recordatorios SAT → `KZ.md` / `LALO.md` / `REMINDERS.md` + **commit/push**.  
MEGA no reemplaza el pull del repo.

---

## 3. Layout esperado

```text
$KZ_MEGA_ROOT/                    # ej. /home/lalo/MEGA  (cambia por máquina)
  kz-memory/                      # ← esto sincroniza MEGA
    organic/
    me/
    social/
    context.md
    incubating.md
    SPACES.md
    README.md

~/kz/                             # clon de kz-agent
  config.local.env                # SOLO local: KZ_MEGA_ROOT=…
  presence/
    organic → …/kz-memory/organic
    me      → …/kz-memory/me
    social  → …/kz-memory/social
    context.md → …
    incubating.md → …
    SPACES.md → …
    fingerprints.tsv   (archivo real, local)
    watch.pid          (local)
  webcam/              (local, no MEGA)
```

---

## 4. Setup en la máquina ACTUAL (ya hecho si leíste esto en el repo actualizado)

Referencia: esta PC usó `KZ_MEGA_ROOT=/home/lalo/MEGA`.

```bash
cd ~/kz
git pull
# config.local.env ya puede existir; si no:
cp -n config.local.env.example config.local.env
# editar KZ_MEGA_ROOT al path real de MEGA en ESTA máquina
~/kz/scripts/kz-memory-link.sh status
~/kz/scripts/kz-memory-link.sh link
~/kz/scripts/kz-memory-link.sh status
```

Comprueba que `presence/me`, `organic`, etc. digan `→ …/kz-memory/…`.

---

## 5. Setup en la OTRA CASA (máquina con fotos) — checklist estricto

**Objetivo:** unir lo que ya está en disco ahí (imágenes de Kz y de Lalo, organic viejo si hay) con lo que baje MEGA **sin pisar lo irrecuperable**.

### Antes de tocar nada

1. **No borres** `~/kz/presence/me` ni `~/kz/presence/social` a mano.
2. **No** ejecutes aún `link` hasta el paso 5.
3. Anota (o fotografía) que existan, por ejemplo:
   - `presence/me/kz-base.jpg`, favoritas
   - `presence/social/lalo-refs/01-cara-frontal.jpg`
   - lo que valores en `organic/`

### Paso 1 — Actualizar el repo

```bash
cd ~/kz
git status          # si hay cambios locales que te importen, anótalos
git pull origin main
```

### Paso 2 — Esperar / tener `kz-memory` de MEGA

- Con cliente MEGA: espera a que aparezca  
  `$KZ_MEGA_ROOT/kz-memory/`  
  (el path de MEGA **no** tiene por qué ser `/home/lalo/MEGA`; el de la otra casa puede ser otro).
- Sin cliente: descarga a mano la carpeta `kz-memory` del cloud a un path fijo y usa `KZ_MEMORY_DIR` (paso 3).

Comprueba:

```bash
ls -la "$KZ_MEGA_ROOT/kz-memory"   # o la ruta donde la bajaste
ls -la "$KZ_MEGA_ROOT/kz-memory/me"
ls -la ~/kz/presence/me 2>/dev/null || true
ls -la ~/kz/presence/social 2>/dev/null || true
```

### Paso 3 — Config local (path de ESTA máquina)

```bash
cd ~/kz
cp -n config.local.env.example config.local.env
```

Edita `config.local.env`:

```bash
# Ejemplo casa A
KZ_MEGA_ROOT="/home/lalo/MEGA"

# Ejemplo otra ruta en casa B
# KZ_MEGA_ROOT="/home/lalo/MEGA Sync"

# Si bajaste kz-memory a mano a un sitio raro:
# KZ_MEMORY_DIR="/ruta/completa/kz-memory"
```

**No** commitees `config.local.env` (está en `.gitignore`).

### Paso 4 — Inspección (sin modificar)

```bash
~/kz/scripts/kz-memory-link.sh status
```

Anota conteos: `me images` en MEGA vs archivos locales en `presence/me`.

### Paso 5 — Enlace seguro (`link`)

```bash
~/kz/scripts/kz-memory-link.sh link
```

El script **no debería** pisar archivos que ya existen en MEGA. Política:

1. Si en `~/kz/presence/me` (o `social` / `organic`) hay un **directorio real** con archivos:
   - Copia a MEGA solo lo que **aún no existe** ahí (`rsync --ignore-existing`).
   - Si el **mismo nombre** existe en ambos y el contenido **difiere**, deja el de MEGA y guarda el local como  
     `nombre.from-<hostname>.bak` **dentro** de la carpeta MEGA (recuperable).
2. Luego mueve el dir local a un backup  
   `presence/me.pre-mega-link.<timestamp>/`  
   y crea el symlink hacia MEGA.
3. Nunca usa `rm -rf` sobre el contenido de MEGA.
4. No toca `webcam/`, fingerprints, pid, notif.

### Paso 6 — Verificar que no se perdieron fotos

```bash
~/kz/scripts/kz-memory-link.sh status
ls -la ~/kz/presence/me/
ls -la ~/kz/presence/social/lalo-refs/ 2>/dev/null
readlink -f ~/kz/presence/me
# Debe resolver dentro de kz-memory

# Buscar backups por si acaso
ls -d ~/kz/presence/*.pre-mega-link.* 2>/dev/null
# source config and search conflict backups:
set -a; source ~/kz/config.local.env; set +a
MEM="${KZ_MEMORY_DIR:-${KZ_MEGA_ROOT%/}/kz-memory}"
find "$MEM" -name '*.from-*.bak' 2>/dev/null
```

Checklist mental:

- [ ] `kz-base.jpg` (o la base que usabas) visible vía `presence/me/`
- [ ] Cara de Lalo en `presence/social/lalo-refs/`
- [ ] Favoritas que te importaban siguen ahí (o en un `.bak` / `pre-mega-link`)
- [ ] `journal` / organic: tiene sentido; si había journal local distinto, busca `.from-<host>.bak`

Si algo falta: **no borres backups**. Copia a mano desde `*.pre-mega-link.*` o `*.from-*.bak` hacia `kz-memory/me/` (o social).

### Paso 7 — Arranque Kz normal

```bash
cd ~/kz && grok
# o en la sesión: campanita según AGENTS.md
~/kz/scripts/kz-memory-link.sh status   # una vez, por calma
```

---

## 6. Comandos del script

```bash
~/kz/scripts/kz-memory-link.sh status   # config + conteos + si hay symlinks
~/kz/scripts/kz-memory-link.sh init     # crea árbol vacío en MEGA (sin linkear)
~/kz/scripts/kz-memory-link.sh link     # merge seguro local→MEGA + symlinks
~/kz/scripts/kz-memory-link.sh unlink   # quita symlinks; NO borra MEGA
```

---

## 7. Día a día

1. Trabajas en una PC → journal y fotos nuevas caen en `kz-memory` → MEGA sube.
2. En la otra PC → MEGA baja → mismos archivos (ya enlazados).
3. Cambios de **canon** (personalidad, protocolo): además `git commit` + `push` en `~/kz`, y `pull` en la otra.
4. Si solo cambias de silla el mismo día: con MEGA al día y links hechos, Kz lee el mismo organic al arrancar.

---

## 8. Rarezas y advertencias que **permanecen**

### 8.1 Edición simultánea

Si dos PCs escriben el **mismo** `journal.md` a la vez, MEGA puede crear copias en conflicto (`journal (1).md`, etc.).  
**Mitigación:** una máquina “activa” a la vez para charla densa; o consolidar a mano tras el viaje.

### 8.2 Desfase MEGA vs Git

- Pull de Git sin esperar MEGA → scripts nuevos pero memoria vieja/vacía.
- MEGA al día sin `git pull` → memoria nueva pero protocolo viejo.  
**Orden sano al llegar a una casa:** `git pull` → esperar `kz-memory` → `status` → (si hace falta) `link`.

### 8.3 Chat de Grok ≠ disco

Una sesión nueva de chat no trae el hilo literal. La continuidad es: organic + canon al arrancar. Resume de chat es opcional y local a esa UI.

### 8.4 Runtime y playbook

El watch reaprende fingerprints en cada PC. El playbook suele ser `~/Workspace/playbook` (todas tus máquinas). Pending/notifs de una casa no “siguen” a la otra (correcto).

### 8.5 Webcam

Snaps **no** van a MEGA. Si quieres una foto en la otra casa, cópiala a propósito o vuelve a capturar.

### 8.6 Conflicto de mismo nombre, distinto contenido

El `link` **no sobrescribe** lo que ya está en MEGA. La copia local distinta queda como `archivo.from-<hostname>.bak` dentro de MEGA.  
Revísalas y elige a mano; no las ignores si son fotos.

### 8.7 `unlink`

Quita symlinks. Los datos siguen en MEGA. Si después creas carpetas reales nuevas en `presence/me` y vuelves a `link`, otra vez merge seguro — pero evita tener dos “fuentes de verdad” reales a la vez.

### 8.8 Repo público

**Nunca** subas `kz-memory`, `presence/`, `webcam/` ni `config.local.env` al GitHub de `kz-agent`.  
El `.gitignore` ya cubre `presence/`, `webcam/`, `config.local.env`.

### 8.9 Primera máquina “vacía” de fotos

Si una PC creó `kz-memory/me` vacío y la otra tenía las fotos solo locales: el `link` en la casa con fotos **rellena** MEGA con lo que faltaba (`--ignore-existing`).  
Después de sync, la PC “vacía” debería ver las fotos al actualizar MEGA (sin re-link si el symlink ya apuntaba bien).

### 8.10 Varios días en una casa y regreso

- La casa que dejas: organic queda en MEGA al sincronizar (no “congelado solo en disco” si MEGA terminó de subir).
- Al volver: espera sync; no hace falta re-link si los symlinks siguen.
- Incubating/context pueden quedar desactualizados respecto a *esta* tarde: Kz debe re-leer y preguntar si duda.

### 8.11 Promote vs organic

Lo importante a largo plazo sigue mereciendo promote a `KZ.md`/`LALO.md` + Git.  
MEGA evita la amnesia del **día a día**; el canon evita depender solo del cloud para identidad.

---

## 9. Si algo sale mal (recuperación)

| Síntoma | Qué hacer |
|---------|-----------|
| `presence/me` vacío tras link | Busca `presence/me.pre-mega-link.*` y `kz-memory/me/*.from-*.bak`; copia a `kz-memory/me/` |
| “No existe padre de la memoria” | `KZ_MEGA_ROOT` mal o MEGA no montado |
| Symlink roto | `readlink`, corrige path en `config.local.env`, `link` de nuevo |
| Duplicados MEGA de conflicto | Abre ambos journals, fusiona a mano en un solo `journal.md`, borra el `(1)` cuando estés seguro |
| Dudas de fotos | **No borres** backups hasta verificar con `ls` y abrir las imágenes |

Recuperación bruta desde backup local:

```bash
# ejemplo: restaurar una base desde pre-mega-link
cp -n ~/kz/presence/me.pre-mega-link.YYYYMMDD-HHMMSS/kz-base.jpg \
      "$KZ_MEGA_ROOT/kz-memory/me/"
```

(`cp -n` = no clobber: no pisa si ya existe destino.)

---

## 10. Resumen de 30 segundos (la otra casa)

```bash
cd ~/kz && git pull
# Esperar kz-memory en MEGA
cp -n config.local.env.example config.local.env
# Editar KZ_MEGA_ROOT (path de ESTA máquina)
~/kz/scripts/kz-memory-link.sh status
# Confirmar que presence/me y social locales AÚN tienen las fotos
~/kz/scripts/kz-memory-link.sh link
~/kz/scripts/kz-memory-link.sh status
ls ~/kz/presence/me/ ~/kz/presence/social/lalo-refs/
# Si falta algo → pre-mega-link.* y *.from-*.bak; no borrar
```

---

## 11. Archivos del repo relacionados

| Archivo | Rol |
|---------|-----|
| **`MEMORY-MEGA.md`** | Esta guía (para ti) |
| `config.local.env.example` | Plantilla de path |
| `config.local.env` | Tu path real (**no** en git) |
| `scripts/kz-memory-link.sh` | init / link seguro / status / unlink |
| `AGENTS.md` | Protocolo del agente (arranque + MEGA) |
| `README.md` | Guía corta; apunta aquí |
| `.gitignore` | `presence/`, `webcam/`, `config.local.env` |

---

*Si algo de esta guía choca con la realidad de una máquina, corrige la guía en el mismo viaje y haz commit — el procedimiento debe seguir siendo verdad.*
