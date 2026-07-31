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
set -euo pipefail

KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
[[ -f "${KZ_HOME}/presence/tts.env" ]] && source "${KZ_HOME}/presence/tts.env"

LANG_CODE="${KZ_TTS_LANG:-es}"
# female1 solo pedía "tipo" y a veces caía en voz grave; forzar síntesis con nombre
VTYPE="${KZ_TTS_VOICE_TYPE:-female1}"
VOICE="${KZ_TTS_VOICE:-Spanish (Spain)+Alicia}"
RATE="${KZ_TTS_RATE:-5}"
PITCH="${KZ_TTS_PITCH:-30}"
VOL="${KZ_TTS_VOLUME:-0}"
WAIT=0

if [[ "${1:-}" == "--wait" || "${1:-}" == "-w" ]]; then
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

if [[ "${WAIT}" == "1" ]]; then
  spd-say "${args[@]}" -- "${text}" >/tmp/kz-say.log 2>&1
  echo "say: done — ${text:0:80}"
else
  nohup spd-say "${args[@]}" -- "${text}" >/tmp/kz-say.log 2>&1 &
  echo "say: pid $! — ${text:0:80}"
fi
