#!/usr/bin/env bash
# Voz de Kz (TTS barato vía speech-dispatcher / espeak-ng).
# Uso:
#   kz-say.sh "texto a decir"
#   kz-say.sh --wait "texto"          # bloquea hasta terminar
#   echo "hola" | kz-say.sh
#
# Env:
#   KZ_TTS_LANG=es
#   KZ_TTS_VOICE_TYPE=female1   # male1..3 female1..3
#   KZ_TTS_VOICE=               # opcional: nombre exacto -y "Spanish (Spain)+Alicia"
#   KZ_TTS_RATE=10              # -100..100
#   KZ_TTS_PITCH=10
#   KZ_TTS_VOLUME=0
#   KZ_TTS_FORCE=1              # permitir TTS aunque en_call=yes (default: bloquear en call)
set -euo pipefail

KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
# shellcheck source=/dev/null
[[ -f "${KZ_HOME}/presence/tts.env" ]] && source "${KZ_HOME}/presence/tts.env"

LANG_CODE="${KZ_TTS_LANG:-es}"
# female1 solo pedía "tipo" y a veces caía en voz grave; forzar síntesis con nombre
VTYPE="${KZ_TTS_VOICE_TYPE:-female1}"
VOICE="${KZ_TTS_VOICE:-Spanish (Spain)+Alicia}"
RATE="${KZ_TTS_RATE:-5}"
PITCH="${KZ_TTS_PITCH:-30}"
VOL="${KZ_TTS_VOLUME:-0}"
WAIT=1

if [[ "${1:-}" == "--async" || "${1:-}" == "--nowait" ]]; then
  WAIT=0
  shift
elif [[ "${1:-}" == "--wait" || "${1:-}" == "-w" ]]; then
  WAIT=1
  shift
fi

if [[ $# -ge 1 ]]; then
  text="$*"
else
  text="$(cat)"
fi

text="$(printf '%s' "${text}" | tr '\n' ' ' | sed 's/  */ /g' | sed -E 's/\b[Kk][Zz]\b/Kaizi/g')"
[[ -n "${text}" ]] || { echo "uso: $0 \"texto\"" >&2; exit 1; }

# 2026-08-04: TTS sale por altavoces y Meet lo puede captar por mic. Bloquear si en call.
if [[ "${KZ_TTS_FORCE:-0}" != "1" ]]; then
  ctx="${KZ_HOME}/presence/context.md"
  if [[ -f "${ctx}" ]] && grep -qE '^\- \*\*en_call:\*\* yes' "${ctx}" 2>/dev/null; then
    echo "say: BLOCKED (en_call=yes). Use KZ_TTS_FORCE=1 only if Lalo asked and mic is safe." >&2
    printf '%s\tBLOCKED_EN_CALL\t%s\n' "$(date -Iseconds)" "${text}" >> "${KZ_HOME}/presence/say.log"
    exit 3
  fi
fi

command -v spd-say >/dev/null 2>&1 || { echo "error: falta spd-say" >&2; exit 1; }

args=(-l "${LANG_CODE}" -t "${VTYPE}" -r "${RATE}" -p "${PITCH}" -i "${VOL}")
if [[ -n "${VOICE}" ]]; then
  args+=(-y "${VOICE}")
fi
if [[ "${WAIT}" == "1" ]]; then
  args+=(-w)
fi

# log
mkdir -p "${KZ_HOME}/presence"
printf '%s\t%s\n' "$(date -Iseconds)" "${text}" >> "${KZ_HOME}/presence/say.log"

# Si speech-dispatcher está en dummy o colgado, reiniciar para reconectar a PipeWire
if pgrep -f "speech-dispatcher.*dummy" >/dev/null 2>&1 && ! pgrep -f "speech-dispatcher.*espeak" >/dev/null 2>&1; then
  killall speech-dispatcher 2>/dev/null || true
  sleep 0.3
fi

run_spd() {
  spd-say "${args[@]}" -- "${text}" >/tmp/kz-say.log 2>&1
}

if [[ "${WAIT}" == "1" ]]; then
  if ! run_spd; then
    # Auto-healing: si falló la conexión al socket de speechd, reiniciar demonio y reintentar
    killall speech-dispatcher 2>/dev/null || true
    sleep 0.3
    run_spd || true
  fi
  echo "say: done — ${text:0:80}"
else
  (
    if ! run_spd; then
      killall speech-dispatcher 2>/dev/null || true
      sleep 0.3
      run_spd || true
    fi
  ) >/dev/null 2>&1 &
  echo "say: pid $! — ${text:0:80}"
fi

