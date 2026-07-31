#!/usr/bin/env bash
# Muestra una imagen de Kz en Gwenview (+ voz opcional).
# Uso:
#   kz-show.sh                         # última / pausa del día
#   kz-show.sh /ruta/a/imagen.jpg
#   kz-show.sh --pausa
#   kz-show.sh --pausa --say "Veinte segundos mirando lejos."
#   kz-show.sh img.jpg --say "Hola"
#   kz-show.sh --say "solo voz"        # sin cambiar imagen (usa última o solo TTS)
set -euo pipefail

KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
VIEWER="${KZ_IMAGE_VIEWER:-gwenview}"
DEFAULT_PAUSA="${KZ_HOME}/presence/me/kz-pausa-ojos-hoy.jpg"
LAST_LINK="${KZ_HOME}/presence/me/kz-last-shown.jpg"

img=""
say_text=""
args=("$@")
i=0
while [[ $i -lt ${#args[@]} ]]; do
  a="${args[$i]}"
  case "$a" in
    --pausa|pausa)
      img="${DEFAULT_PAUSA}"
      ;;
    --say)
      i=$((i + 1))
      say_text="${args[$i]:-}"
      ;;
    --say=*)
      say_text="${a#--say=}"
      ;;
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# //'
      exit 0
      ;;
    *)
      if [[ -z "${img}" && -f "$a" ]]; then
        img="$a"
      elif [[ -z "${img}" && -z "${say_text}" && "$a" != --* ]]; then
        # texto suelto solo si no hay flags raros
        img=""
      fi
      ;;
  esac
  i=$((i + 1))
done

# default image
if [[ -z "${img}" ]]; then
  if [[ -f "${LAST_LINK}" ]]; then
    img="${LAST_LINK}"
  elif [[ -f "${DEFAULT_PAUSA}" ]]; then
    img="${DEFAULT_PAUSA}"
  fi
fi

if [[ -n "${img}" ]]; then
  if [[ ! -f "${img}" ]]; then
    echo "error: no existe ${img}" >&2
    exit 1
  fi
  ln -f "${img}" "${LAST_LINK}" 2>/dev/null || cp -f "${img}" "${LAST_LINK}"
  if ! command -v "${VIEWER}" >/dev/null 2>&1; then
    echo "error: no está ${VIEWER}" >&2
    exit 1
  fi
  nohup "${VIEWER}" "${img}" >/tmp/kz-show-gwenview.log 2>&1 &
  echo "show: ${VIEWER} → ${img} (pid $!)"
fi

if [[ -n "${say_text}" ]]; then
  # Campanita y tray notification
  if [[ -x "${KZ_HOME}/scripts/kz-nudge.sh" ]]; then
    "${KZ_HOME}/scripts/kz-nudge.sh" --say "${say_text}" || true
  fi
  # Voz de Kz (con --wait para asegurar reproducción completa)
  if [[ -x "${KZ_HOME}/scripts/kz-say.sh" ]]; then
    "${KZ_HOME}/scripts/kz-say.sh" --wait "${say_text}"
  else
    spd-say -l es -t female1 -w -- "${say_text}" || true
  fi
fi

if [[ -z "${img}" && -z "${say_text}" ]]; then
  echo "uso: $0 [--pausa] [imagen.jpg] [--say \"texto\"]" >&2
  exit 1
fi
