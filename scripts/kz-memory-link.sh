#!/usr/bin/env bash
# Enlaza la memoria de Kz (orgánica + mente + assets visuales) a una carpeta MEGA.
# Runtime (pid, fingerprints, pending, notif, webcam) se queda solo en ~/kz/presence.
#
# Merge seguro al linkear: no pisa archivos que ya existen en MEGA.
# Si local y MEGA difieren en el mismo path, conserva MEGA y guarda local como
#   nombre.from-<hostname>.bak  dentro del árbol MEGA.
#
# Uso:
#   kz-memory-link.sh status
#   kz-memory-link.sh init      # crea árbol en MEGA si falta
#   kz-memory-link.sh link      # merge seguro + symlinks en presence/
#   kz-memory-link.sh unlink    # quita symlinks (no borra MEGA)
#
# Config (por máquina):
#   config.local.env → KZ_MEGA_ROOT=/path/al/MEGA
#   opcional KZ_MEMORY_DIR (default: $KZ_MEGA_ROOT/kz-memory)
#
# Guía humana: ~/kz/MEMORY-MEGA.md
set -euo pipefail

KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "${KZ_HOME}/config.env"
if [[ -f "${KZ_HOME}/config.local.env" ]]; then
  # shellcheck source=/dev/null
  source "${KZ_HOME}/config.local.env"
fi

PRESENCE="${KZ_HOME}/presence"
MEMORY_NAME="kz-memory"
HOST_TAG="$(hostname -s 2>/dev/null || hostname | cut -d. -f1 || echo host)"

die() { echo "error: $*" >&2; exit 1; }

resolve_memory_dir() {
  if [[ -n "${KZ_MEMORY_DIR:-}" ]]; then
    echo "${KZ_MEMORY_DIR}"
    return
  fi
  if [[ -n "${KZ_MEGA_ROOT:-}" ]]; then
    echo "${KZ_MEGA_ROOT%/}/${MEMORY_NAME}"
    return
  fi
  echo ""
}

# Piezas que SÍ viajan entre máquinas (viven en MEGA, se enlazan aquí)
SHARED_DIRS=(organic me social)
SHARED_FILES=(context.md incubating.md SPACES.md)

# Nombres que NUNCA deben ser symlink a MEGA (runtime local)
LOCAL_ONLY_HINT="fingerprints.tsv watch.pid pending.md events.log nudge.log notif/ *.pid *.log"

memory_dir="$(resolve_memory_dir)"

need_memory_dir() {
  [[ -n "${memory_dir}" ]] || die "define KZ_MEGA_ROOT o KZ_MEMORY_DIR en config.local.env (ver config.local.env.example y MEMORY-MEGA.md)"
}

ensure_memory_tree() {
  need_memory_dir
  local root_parent
  root_parent="$(dirname "${memory_dir}")"
  [[ -d "${root_parent}" ]] || die "no existe el padre de la memoria: ${root_parent} (¿MEGA montado / path mal?)"

  mkdir -p "${memory_dir}/organic" "${memory_dir}/me" "${memory_dir}/social/lalo-refs" \
    "${memory_dir}/social/oficina-lalo"

  local f
  for f in journal.md working.md patterns.md promoted.log; do
    [[ -f "${memory_dir}/organic/${f}" ]] || : > "${memory_dir}/organic/${f}"
  done

  if [[ ! -f "${memory_dir}/context.md" ]]; then
    cat > "${memory_dir}/context.md" << EOF
# Contexto activo de Kz

- **actualizado:** $(date '+%Y-%m-%d %H:%M')
- **primary:** company
- **secondary:** monitora
- **en_call:** no
- **mood_lalo (sospecha):**
- **foco_ahora:**
- **notas:**
  - (bootstrap multi-máquina vía MEGA)
EOF
  fi

  if [[ ! -f "${memory_dir}/incubating.md" ]]; then
    echo "# Temas en incubación" > "${memory_dir}/incubating.md"
  fi

  if [[ ! -f "${memory_dir}/SPACES.md" ]]; then
    cat > "${memory_dir}/SPACES.md" << 'EOF'
# Espacios mentales de Kz (mapa)

- **monitora** — vigilancia playbook / rarezas
- **company** — compañía y conversación
- **craft** — construir en ~/kz
- **rest** — silencio cómodo, sin empujar
EOF
  fi

  if [[ ! -f "${memory_dir}/README.md" ]]; then
    cat > "${memory_dir}/README.md" << EOF
# kz-memory — memoria de Kz entre máquinas

Sincronizado por **MEGA** (no por GitHub).

Guía completa en el repo: \`~/kz/MEMORY-MEGA.md\` (tras git pull).

| Path | Rol |
|------|-----|
| organic/ | journal, working, patterns |
| me/ | bases y favoritas de Kz |
| social/ | refs de Lalo, oficina… |
| context.md, incubating.md, SPACES.md | mente |

No va aquí: pid, fingerprints, pending, notif, webcam.

Generado: $(date -Iseconds)
EOF
  fi
}

is_link_to() {
  local path="$1" target="$2"
  [[ -L "${path}" ]] || return 1
  local resolved want
  resolved="$(readlink -f "${path}" 2>/dev/null || true)"
  want="$(readlink -f "${target}" 2>/dev/null || echo "${target}")"
  [[ "${resolved}" == "${want}" ]]
}

count_files() {
  local d="$1"
  [[ -d "${d}" ]] || { echo 0; return; }
  find "${d}" -type f 2>/dev/null | wc -l
}

# Copia local → MEGA sin pisar lo que ya existe en MEGA.
# Conflictos de contenido (mismo path relativo, hash distinto):
#   deja MEGA y escribe  <rel>.from-<host>.bak  junto al archivo en MEGA.
merge_local_dir_into_mega() {
  local local_dir="$1"
  local mega_dir="$2"
  local label="$3"

  [[ -d "${local_dir}" ]] || return 0
  [[ -L "${local_dir}" ]] && return 0
  mkdir -p "${mega_dir}"

  local n_local n_mega
  n_local="$(count_files "${local_dir}")"
  n_mega="$(count_files "${mega_dir}")"
  echo "merge ${label}: local=${n_local} archivos, mega=${n_mega} archivos (MEGA no se pisa)"

  # 1) Archivos que solo están en local → entran a MEGA
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --ignore-existing "${local_dir}/" "${mega_dir}/"
  else
    # fallback tosco sin rsync
    (cd "${local_dir}" && find . -type f -print0) | while IFS= read -r -d '' rel; do
      rel="${rel#./}"
      if [[ ! -e "${mega_dir}/${rel}" ]]; then
        mkdir -p "$(dirname "${mega_dir}/${rel}")"
        cp -a "${local_dir}/${rel}" "${mega_dir}/${rel}"
      fi
    done
  fi

  # 2) Mismo path, distinto contenido → backup del local dentro de MEGA
  local conflicts=0
  while IFS= read -r -d '' rel; do
    rel="${rel#./}"
    local lf mf
    lf="${local_dir}/${rel}"
    mf="${mega_dir}/${rel}"
    [[ -f "${mf}" ]] || continue
    if ! cmp -s "${lf}" "${mf}" 2>/dev/null; then
      local bak="${mega_dir}/${rel}.from-${HOST_TAG}.bak"
      # no pisar un bak previo idéntico
      if [[ -f "${bak}" ]] && cmp -s "${lf}" "${bak}" 2>/dev/null; then
        continue
      fi
      mkdir -p "$(dirname "${bak}")"
      cp -a "${lf}" "${bak}"
      echo "  conflicto: ${label}/${rel} → conservado MEGA; local en $(basename "${bak}")"
      conflicts=$((conflicts + 1))
    fi
  done < <(cd "${local_dir}" && find . -type f -print0 2>/dev/null)

  if (( conflicts > 0 )); then
    echo "  aviso: ${conflicts} conflicto(s) en ${label}. Revisa *.from-${HOST_TAG}.bak en MEGA (ver MEMORY-MEGA.md)."
  fi
}

merge_local_file_into_mega() {
  local local_file="$1"
  local mega_file="$2"
  local label="$3"

  [[ -f "${local_file}" ]] || return 0
  [[ -L "${local_file}" ]] && return 0

  if [[ ! -f "${mega_file}" ]]; then
    mkdir -p "$(dirname "${mega_file}")"
    cp -a "${local_file}" "${mega_file}"
    echo "merge file ${label}: local → MEGA (no existía)"
    return 0
  fi

  if cmp -s "${local_file}" "${mega_file}" 2>/dev/null; then
    return 0
  fi

  # MEGA gana; resguardar local
  local bak="${mega_file}.from-${HOST_TAG}.bak"
  cp -a "${local_file}" "${bak}"
  echo "  conflicto file ${label}: conservado MEGA; local en $(basename "${bak}")"
}

backup_if_real() {
  local path="$1"
  [[ -e "${path}" || -L "${path}" ]] || return 0
  if [[ -L "${path}" ]]; then
    # symlink a otro sitio: quitar solo el link, no el target
    return 0
  fi
  local bak="${path}.pre-mega-link.$(date +%Y%m%d-%H%M%S)"
  echo "backup local: ${path} → ${bak}"
  mv -f "${path}" "${bak}"
}

do_link() {
  ensure_memory_tree
  mkdir -p "${PRESENCE}"

  local name src dst
  for name in "${SHARED_DIRS[@]}"; do
    src="${memory_dir}/${name}"
    dst="${PRESENCE}/${name}"
    mkdir -p "${src}"

    if is_link_to "${dst}" "${src}"; then
      echo "ok  dir  ${name} → ya enlazado"
      continue
    fi

    # Si hay dir/archivo real local, fusionar hacia MEGA ANTES de mover
    if [[ -d "${dst}" && ! -L "${dst}" ]]; then
      merge_local_dir_into_mega "${dst}" "${src}" "${name}"
    fi

    if [[ -L "${dst}" ]]; then
      # apuntaba a otro lado
      echo "aviso: ${dst} era symlink a $(readlink "${dst}"); se reescribe"
      rm -f "${dst}"
    else
      backup_if_real "${dst}"
    fi

    ln -s "${src}" "${dst}"
    echo "link dir  ${dst} → ${src}"
  done

  for name in "${SHARED_FILES[@]}"; do
    src="${memory_dir}/${name}"
    dst="${PRESENCE}/${name}"
    # asegurar que el target en MEGA exista (ensure ya crea defaults)
    [[ -f "${src}" ]] || continue

    if is_link_to "${dst}" "${src}"; then
      echo "ok  file ${name} → ya enlazado"
      continue
    fi

    if [[ -f "${dst}" && ! -L "${dst}" ]]; then
      merge_local_file_into_mega "${dst}" "${src}" "${name}"
    fi

    if [[ -L "${dst}" ]]; then
      rm -f "${dst}"
    else
      backup_if_real "${dst}"
    fi

    ln -s "${src}" "${dst}"
    echo "link file ${dst} → ${src}"
  done

  echo
  echo "memoria enlazada. MEGA: ${memory_dir}"
  echo "local-only: ${PRESENCE}/ (${LOCAL_ONLY_HINT})"
  echo "guía: ${KZ_HOME}/MEMORY-MEGA.md"
  echo "post-check: ls presence/me presence/social; status"
}

do_unlink() {
  mkdir -p "${PRESENCE}"
  local name dst
  for name in "${SHARED_DIRS[@]}" "${SHARED_FILES[@]}"; do
    dst="${PRESENCE}/${name}"
    if [[ -L "${dst}" ]]; then
      rm -f "${dst}"
      echo "unlinked ${dst}"
    fi
  done
  echo "listo (contenido en MEGA intacto)."
}

do_status() {
  echo "KZ_HOME=${KZ_HOME}"
  echo "config.local.env=$([ -f "${KZ_HOME}/config.local.env" ] && echo sí || echo no)"
  echo "KZ_MEGA_ROOT=${KZ_MEGA_ROOT:-"(no definido)"}"
  echo "KZ_MEMORY_DIR=${memory_dir:-"(no resuelto)"}"
  echo "guía: ${KZ_HOME}/MEMORY-MEGA.md"
  if [[ -n "${memory_dir}" ]]; then
    if [[ -d "${memory_dir}" ]]; then
      echo "memory tree: existe"
      echo "  organic files: $(count_files "${memory_dir}/organic")"
      echo "  me files:      $(count_files "${memory_dir}/me")"
      echo "  social files:  $(count_files "${memory_dir}/social")"
      local j="${memory_dir}/organic/journal.md"
      if [[ -f "${j}" ]]; then
        echo "  journal lines: $(wc -l < "${j}")  mtime=$(date -r "${j}" '+%Y-%m-%d %H:%M' 2>/dev/null || echo '?')"
      fi
      local baks
      baks="$(find "${memory_dir}" -name '*.from-*.bak' 2>/dev/null | wc -l)"
      echo "  conflict bak:  ${baks} (*.from-*.bak)"
    else
      echo "memory tree: AÚN NO (corre: kz-memory-link.sh init|link)"
    fi
  fi
  echo
  echo "symlinks en presence/:"
  local name dst
  for name in "${SHARED_DIRS[@]}" "${SHARED_FILES[@]}"; do
    dst="${PRESENCE}/${name}"
    if [[ -L "${dst}" ]]; then
      echo "  ${name} → $(readlink "${dst}")"
    elif [[ -e "${dst}" ]]; then
      echo "  ${name}  (local real, NO link a MEGA) files=$(count_files "${dst}")"
    else
      echo "  ${name}  (ausente)"
    fi
  done
  local pre
  pre="$(ls -d "${PRESENCE}"/*.pre-mega-link.* 2>/dev/null | wc -l || true)"
  echo "backups pre-mega-link en presence/: ${pre}"
}

cmd="${1:-status}"
case "${cmd}" in
  status|st) do_status ;;
  init) ensure_memory_tree; echo "init ok: ${memory_dir}" ;;
  link|setup) do_link ;;
  unlink) do_unlink ;;
  *)
    echo "uso: $0 status|init|link|unlink" >&2
    echo "guía: ${KZ_HOME}/MEMORY-MEGA.md" >&2
    exit 1
    ;;
esac
