#!/usr/bin/env bash
# Llamar la atención de Lalo: notificación de escritorio + sonido.
#
# Uso:
#   kz-nudge.sh [título] [cuerpo]
#   kz-nudge.sh --soft [título] [cuerpo]     # solo sonido (+ cuerpo opcional sin popup)
#   kz-nudge.sh --terminal [pista_corta]     # "voltea a la terminal de Kz/Grok"
#   kz-nudge.sh --say "comentario personal"  # título Kz + cuerpo = comentario (recortado al tray)
#
# notify-send suele truncar cuerpos largos: el comentario completo va en el chat de Grok.
set -euo pipefail

KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
SOUND="${KZ_NUDGE_SOUND:-/usr/share/sounds/freedesktop/stereo/message-new-instant.oga}"
SOFT_SOUND="${KZ_NUDGE_SOFT_SOUND:-/usr/share/sounds/freedesktop/stereo/bell.oga}"
# Límite práctico de cuerpo en tray (caracteres); el resto vive en la terminal/chat
MAX_BODY="${KZ_NUDGE_MAX_BODY:-220}"

export DISPLAY="${DISPLAY:-:0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

soft=0
mode="normal"
title="Kz"
body=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --soft) soft=1; shift ;;
    --terminal)
      mode="terminal"
      shift
      body="${1:-Te escribí en la terminal de Grok (Kz). Voltea a ver.}"
      shift || true
      title="Kz · mira la terminal"
      break
      ;;
    --say)
      mode="say"
      shift
      body="${1:-Oye…}"
      shift || true
      title="Kz"
      break
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "uso: kz-nudge.sh [--soft] [--say texto|--terminal [pista]|título cuerpo]" >&2
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

if [[ "${mode}" == "normal" ]]; then
  title="${1:-Kz}"
  body="${2:-Oye… ¿me miras un segundo?}"
fi

# Una sola línea para el tray (sin saltos raros)
body_flat="$(printf '%s' "${body}" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ //;s/ $//')"
if ((${#body_flat} > MAX_BODY)); then
  body_tray="${body_flat:0:$((MAX_BODY - 1))}…"
  truncated=1
else
  body_tray="${body_flat}"
  truncated=0
fi

play() {
  local f="$1"
  [[ -f "$f" ]] || return 1
  if command -v paplay >/dev/null 2>&1; then
    paplay "$f" 2>/dev/null && return 0
  fi
  if command -v pw-play >/dev/null 2>&1; then
    pw-play "$f" 2>/dev/null && return 0
  fi
  return 1
}

if (( soft == 0 )) && command -v notify-send >/dev/null 2>&1; then
  notify-send -u normal -a "Kz" -i dialog-information "$title" "$body_tray" 2>/dev/null || true
fi

if (( soft == 1 )); then
  play "$SOFT_SOUND" || play "$SOUND" || true
else
  play "$SOUND" || play "$SOFT_SOUND" || true
fi

mkdir -p "${KZ_HOME}/presence"
{
  echo "$(date -Iseconds) nudge mode=${mode} truncated=${truncated}"
  echo "  title: ${title}"
  echo "  body: ${body_flat}"
} >> "${KZ_HOME}/presence/nudge.log"

# Último mensaje completo (para que el agente o Lalo lo relean)
printf '%s\n' "${body}" > "${KZ_HOME}/presence/last_nudge_body.txt"
