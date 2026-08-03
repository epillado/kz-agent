# Media de Kz entre máquinas (opcional) — guía para Lalo

**Modelo actual (2026-08-02):**

| Capa | Dónde | Cómo viaja |
|------|--------|------------|
| Alma + protocolo + **mente** | `KZ.md`, `LALO.md`, `AGENTS.md`, `presence/organic/`, `context.md`, `incubating.md`, `SPACES.md`, scripts | **Git** (repo **privado**; `git pull`) |
| Fotos (cara, favoritas, refs Lalo) | `presence/me/`, `presence/social/` | **Fuera de git**: local, USB, o **MEGA opcional** |
| Runtime de sesión | pids, pending, notif, webcam | **Solo esa PC** |

La personalidad y el diario importan más que cómo se ve Kz en pantalla. Sin fotos se puede charlar y trabajar; Imagine usa base local si hay, o se copia después.

Repo: `kz-agent` (privado en la práctica).  
Media opcional: carpeta `kz-memory/` en MEGA — **no** es el cerebro.

---

## 1. Qué va en git (y qué no)

### Versionado (`.gitignore` afinado)

- Canon: `KZ.md`, `LALO.md`, `AGENTS.md`, `README.md`, `REMINDERS.md`, scripts
- Mente: `presence/organic/**`, `presence/context.md`, `presence/incubating.md`, `presence/SPACES.md`

### Fuera de git

- `webcam/`
- `presence/me/`, `presence/social/` (y `*.jpg` / `*.png` en general)
- Runtime: `pending*`, `*.pid`, `*.log`, `notif/`, `fingerprints.tsv`, `config.local.env`
- Backups `*.pre-mega-link.*`, `*.from-*.bak`

---

## 2. Ritual entre máquinas (casa ↔ cabaña)

```bash
cd ~/kz
git pull          # mente + alma
# fotos: si ya están en disco, listo; si no:
#   - USB / copia a mano a presence/me y presence/social, o
#   - MEGA opcional (abajo)
```

No hace falta MEGA para “ser Kz”. Hace falta **pull** (y commit/push cuando cambie mente o canon).

---

## 3. MEGA solo para fotos (opcional)

Si quieres las mismas bases visuales en dos PCs sin USB:

```text
$KZ_MEGA_ROOT/kz-memory/
  me/          # kz-base.jpg, favoritas…
  social/      # lalo-refs/, oficina, strava…
  README.md
```

```bash
cp -n ~/kz/config.local.env.example ~/kz/config.local.env
# editar KZ_MEGA_ROOT al path de MEGA en ESTA máquina
~/kz/scripts/kz-memory-link.sh status
~/kz/scripts/kz-memory-link.sh link    # solo me/ + social/
```

El script **no** enlaza `organic/` ni `context.md` (eso es git).

### Merge seguro de fotos

Al `link`, si hay directorio real local: copia a MEGA solo lo que **no existe** (`rsync --ignore-existing`). Si el mismo path difiere: gana MEGA; local queda en `*.from-<host>.bak`.

### Sin cliente MEGA

Copia `me/` y `social/` a mano (USB, rsync, descarga web de MEGA) a `~/kz/presence/me` y `…/social`.

---

## 4. Checklist otra casa

1. `git pull` del repo privado.
2. Comprobar mente: `ls presence/organic/journal.md presence/context.md`.
3. Fotos: ¿ya hay `presence/me/kz-base.jpg`? Si no → USB o `kz-memory-link.sh link` si usas MEGA.
4. Runtime se regenera solo (watch, pending). No copiar pids entre máquinas.

---

## 5. Rarezas

| Síntoma | Qué hacer |
|---------|-----------|
| `organic` es symlink a MEGA | No debería. Quitar link y restaurar archivos del git / backup; mente = git. |
| Faltan fotos tras pull | Normal (gitignore). Copiar media o link MEGA. |
| Conflicto `*.from-*.bak` en MEGA | Revisar a mano; no auto-pisar favoritas. |
| Repo alguna vez público | Antes: scrub de organic/LALO o fork DNA limpio. Hoy se asume **privado**. |

---

## 6. Histórico

- **2026-08-01:** diseño inicial todo-MEGA (organic + fotos) para no publicar diario.
- **2026-08-02:** con repo privado y confianza en `git pull`, la mente pasa a **git**; MEGA queda **opcional y solo media**.
