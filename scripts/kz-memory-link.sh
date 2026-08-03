#!/usr/bin/env bash
# Enlace opcional de **fotos** de Kz (me/ + social/) a una carpeta MEGA u otra ruta.
#
# Modelo 2026-08-02:
#   - Personalidad + mente (organic, context, incubating, SPACES) → **git** (pull).
#   - Fotos → fuera de git: local, USB, o este script → MEGA (opcional).
#   - Runtime (pid, fingerprints, pending, notif, webcam) → solo local.
#
# Uso:
#   kz-memory-link.sh status
#   kz-memory-link.sh init      # crea árbol de media en MEGA si falta
#   kz-memory-link.sh link      # merge seguro + symlinks presence/me y social
#   kz-memory-link.sh unlink    # quita symlinks (no borra MEGA ni git)
#
# Config (por máquina):
#   config.local.env → KZ_MEGA_ROOT=/path/al/MEGA
#   opcional KZ_MEMORY_DIR (default: $KZ_MEGA_ROOT/kz-memory)
#
# Guía: ~/kz/MEMORY-MEGA.md
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

# Solo media (fotos). Texto de mente NO se enlaza — va por git.
MEDIA_DIRS=(me social)

memory_dir="$(resolve_memory_dir)"

need_memory_dir() {
  [[ -n "${memory_dir}" ]] || die "define KZ_MEGA_ROOT o KZ_MEMORY_DIR en config.local.env (ver config.local.env.example y MEMORY-MEGA.md)"
}

ensure_memory_tree() {
  need_memory_dir
  local root_parent
  root_parent="$(dirname "${memory_dir}")"
  [[ -d "${root_parent}" ]] || die "no existe el padre de la media: ${root_parent} (¿MEGA montado / path mal?)"

  mkdir -p "${memory_dir}/me" "${memory_dir}/social/lalo-refs" \
    "${memory_dir}/social/oficina-lalo"

  if [[ ! -f "${memory_dir}/README.md" ]]; then
    cat > "${memory_dir}/README.md" << EOF
# kz-memory — media de Kz (opcional)

Solo **fotos** (me/, social/). La mente y el diario van por **git** del repo privado.

Guía: \`~/kz/MEMORY-MEGA.md\` (tras git pull).

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

  if command -v rsync >/dev/null 2>&1; then
    rsync -a --ignore-existing "${local_dir}/" "${mega_dir}/"
  else
    (cd "${local_dir}" && find . -type f -print0) | while IFS= read -r -d '' rel; do
      rel="${rel#./}"
      if [[ ! -e "${mega_dir}/${rel}" ]]; then
        mkdir -p "$(dirname "${mega_dir}/${rel}")"
        cp -a "${local_dir}/${rel}" "${mega_dir}/${rel}"
      fi
    done
  fi

  local conflicts=0
  while IFS= read -r -d '' rel; do
    rel="${rel#./}"
    local lf mf
    lf="${local_dir}/${rel}"
    mf="${mega_dir}/${rel}"
    [[ -f "${mf}" ]] || continue
    if ! cmp -s "${lf}" "${mf}" 2>/dev/null; then
      local bak="${mega_dir}/${rel}.from-${HOST_TAG}.bak"
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
    echo "  aviso: ${conflicts} conflicto(s) en ${label}. Revisa *.from-${HOST_TAG}.bak en MEGA."
  fi
}

backup_if_real() {
  local path="$1"
  [[ -e "${path}" || -L "${path}" ]] || return 0
  if [[ -L "${path}" ]]; then
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
  for name in "${MEDIA_DIRS[@]}"; do
    src="${memory_dir}/${name}"
    dst="${PRESENCE}/${name}"
    mkdir -p "${src}"

    if is_link_to "${dst}" "${src}"; then
      echo "ok  dir  ${name} → ya enlazado"
      continue
    fi

    if [[ -d "${dst}" && ! -L "${dst}" ]]; then
      merge_local_dir_into_mega "${dst}" "${src}" "${name}"
    fi

    if [[ -L "${dst}" ]]; then
      echo "aviso: ${dst} era symlink a $(readlink "${dst}"); se reescribe"
      rm -f "${dst}"
    else
      backup_if_real "${dst}"
    fi

    ln -s "${src}" "${dst}"
    echo "link dir  ${dst} → ${src}"
  done

  echo
  echo "media enlazada (solo me/ + social/). MEGA: ${memory_dir}"
  echo "mente/organic: van por git en presence/ (no por este script)"
  echo "guía: ${KZ_HOME}/MEMORY-MEGA.md"
}

do_unlink() {
  mkdir -p "${PRESENCE}"
  local name dst
  for name in "${MEDIA_DIRS[@]}"; do
    dst="${PRESENCE}/${name}"
    if [[ -L "${dst}" ]]; then
      rm -f "${dst}"
      echo "unlinked ${dst}"
    fi
  done
  echo "listo (contenido en MEGA intacto). organic/context no se tocan."
}

do_status() {
  echo "KZ_HOME=${KZ_HOME}"
  echo "config.local.env=$([ -f "${KZ_HOME}/config.local.env" ] && echo sí || echo no)"
  echo "KZ_MEGA_ROOT=${KZ_MEGA_ROOT:-"(no definido)"}"
  echo "KZ_MEMORY_DIR=${memory_dir:-"(no resuelto)"}"
  echo "modelo: texto mente → git; fotos → local/USB/MEGA opcional"
  echo "guía: ${KZ_HOME}/MEMORY-MEGA.md"
  if [[ -n "${memory_dir}" ]]; then
    if [[ -d "${memory_dir}" ]]; then
      echo "media tree: existe"
      echo "  me files:     $(count_files "${memory_dir}/me")"
      echo "  social files: $(count_files "${memory_dir}/social")"
      local baks
      baks="$(find "${memory_dir}" -name '*.from-*.bak' 2>/dev/null | wc -l)"
      echo "  conflict bak: ${baks} (*.from-*.bak)"
    else
      echo "media tree: AÚN NO (opcional: kz-memory-link.sh init|link)"
    fi
  fi
  echo
  echo "presence/ (texto git vs media):"
  local name dst
  for name in organic context.md incubating.md SPACES.md; do
    dst="${PRESENCE}/${name}"
    if [[ -L "${dst}" ]]; then
      echo "  ${name} → $(readlink "${dst}")  ⚠ debería ser archivo real en git"
    elif [[ -e "${dst}" ]]; then
      if [[ -d "${dst}" ]]; then
        echo "  ${name}/  (local/git) files=$(count_files "${dst}")"
      else
        echo "  ${name}  (local/git) bytes=$(wc -c < "${dst}")"
      fi
    else
      echo "  ${name}  (ausente)"
    fi
  done
  for name in "${MEDIA_DIRS[@]}"; do
    dst="${PRESENCE}/${name}"
    if [[ -L "${dst}" ]]; then
      echo "  ${name}/ → $(readlink "${dst}")  (media, fuera de git)"
    elif [[ -e "${dst}" ]]; then
      echo "  ${name}/  (local real, fuera de git) files=$(count_files "${dst}")"
    else
      echo "  ${name}/  (ausente — USB/MEGA/copia a mano)"
    fi
  done
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
