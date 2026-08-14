#!/usr/bin/env bash
# Biblioteca común para scripts de cámara Kz
set -euo pipefail

KZ_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${KZ_HOME}/config.env"
# shellcheck source=/dev/null
[[ -f "${KZ_HOME}/config.local.env" ]] && source "${KZ_HOME}/config.local.env"

WEBCAM_DIR="${KZ_HOME}/webcam"
BURST_DIR="${WEBCAM_DIR}/burst"
ARCHIVE_DIR="${WEBCAM_DIR}/archive"
LATEST_JPG="${WEBCAM_DIR}/latest.jpg"
LATEST_META="${WEBCAM_DIR}/meta.json"

mkdir -p "${WEBCAM_DIR}" "${BURST_DIR}" "${ARCHIVE_DIR}"

die() {
  echo "error: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "falta el comando: $1"
}

check_device() {
  [[ -e "${KZ_DEVICE}" ]] || die "no existe el dispositivo ${KZ_DEVICE}"
  [[ -r "${KZ_DEVICE}" && -w "${KZ_DEVICE}" ]] || die "sin permisos sobre ${KZ_DEVICE} (¿grupo video / ACL?)"
}

# Captura un JPEG a $1. Etiqueta opcional $2 para meta/archive.
# Imprime en stdout la ruta de latest.jpg
capture_frame() {
  local dest="$1"
  local label="${2:-snap}"
  local tmp
  tmp="$(mktemp --suffix=.jpg "${WEBCAM_DIR}/.cap.XXXXXX")"

  require_cmd ffmpeg
  check_device

  local -a ff_common=(
    -hide_banner -loglevel error
    -f v4l2
    -video_size "${KZ_RESOLUTION}"
    -i "${KZ_DEVICE}"
    -frames:v 1
    -q:v 2
    -y
  )

  # Preferir MJPEG (C920); si falla, reintentar sin forzar input_format
  if ! ffmpeg -input_format "${KZ_INPUT_FORMAT}" "${ff_common[@]}" "${tmp}" 2>/dev/null; then
    ffmpeg "${ff_common[@]}" "${tmp}" || die "ffmpeg no pudo capturar desde ${KZ_DEVICE}"
  fi

  # Warm-up: segunda captura tras una pausa (autofocus/exposición)
  if [[ -n "${KZ_WARMUP_SEC}" && "${KZ_WARMUP_SEC}" != "0" && "${KZ_WARMUP_SEC}" != "0.0" ]]; then
    sleep "${KZ_WARMUP_SEC}"
    local tmp2
    tmp2="$(mktemp --suffix=.jpg "${WEBCAM_DIR}/.cap.XXXXXX")"
    if ffmpeg -input_format "${KZ_INPUT_FORMAT}" "${ff_common[@]}" "${tmp2}" 2>/dev/null \
       || ffmpeg "${ff_common[@]}" "${tmp2}" 2>/dev/null; then
      mv -f "${tmp2}" "${tmp}"
    else
      rm -f "${tmp2}"
    fi
  fi

  [[ -s "${tmp}" ]] || die "captura vacía"
  mkdir -p "$(dirname "${dest}")"
  mv -f "${tmp}" "${dest}"

  local ts stamp archived
  ts="$(date -Iseconds)"
  stamp="$(date +%Y%m%d-%H%M%S)"
  archived="${ARCHIVE_DIR}/${stamp}-${label}.jpg"

  if [[ "$(realpath -m "${dest}")" != "$(realpath -m "${LATEST_JPG}")" ]]; then
    cp -f "${dest}" "${LATEST_JPG}"
  fi
  cp -f "${LATEST_JPG}" "${archived}"

  write_meta "${label}" "${ts}" "${archived}" "${dest}"
  echo "${LATEST_JPG}"
}

write_meta() {
  local label="$1"
  local ts="$2"
  local archived="$3"
  local dest="$4"
  local bytes size
  bytes="$(stat -c%s "${LATEST_JPG}" 2>/dev/null || echo 0)"
  if command -v identify >/dev/null 2>&1; then
    size="$(identify -format '%wx%h' "${LATEST_JPG}" 2>/dev/null || echo "${KZ_RESOLUTION}")"
  else
    size="${KZ_RESOLUTION}"
  fi

  cat > "${LATEST_META}" <<EOF
{
  "label": "${label}",
  "timestamp": "${ts}",
  "device": "${KZ_DEVICE}",
  "requested_resolution": "${KZ_RESOLUTION}",
  "actual_size": "${size}",
  "bytes": ${bytes},
  "latest": "${LATEST_JPG}",
  "source": "${dest}",
  "archive": "${archived}",
  "host": "$(hostname)",
  "user": "$(id -un)"
}
EOF
}
