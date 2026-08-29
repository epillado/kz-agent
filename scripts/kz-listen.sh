#!/usr/bin/env bash
# Oídos de Kz: Transcripción local de voz vía whisper.cpp + PipeWire
# Uso:
#   kz-listen.sh               # Graba 5 segundos del mic y transcribe
#   kz-listen.sh 8             # Graba 8 segundos
#   kz-listen.sh --start       # Inicia grabación (Push-to-talk ON)
#   kz-listen.sh --stop        # Detiene grabación, transcribe y muestra texto (Push-to-talk OFF)
#   kz-listen.sh --file ruta   # Transcribe un archivo .wav existente
#
set -euo pipefail

KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
WHISPER_BIN="${KZ_HOME}/tools/whisper.cpp/build/bin/whisper-cli"
MODEL_BIN="${KZ_HOME}/tools/whisper.cpp/models/ggml-small.bin"
[[ -f "${MODEL_BIN}" ]] || MODEL_BIN="${KZ_HOME}/tools/whisper.cpp/models/ggml-base.bin"
AUDIO_TMP="/tmp/kz-listen-mic.wav"
PID_FILE="/tmp/kz-listen.pid"
LOG_FILE="${KZ_HOME}/presence/listen.log"

[[ -x "${WHISPER_BIN}" ]] || { echo "error: falta whisper-cli en ${WHISPER_BIN}" >&2; exit 1; }
[[ -f "${MODEL_BIN}" ]] || { echo "error: falta modelo en ${MODEL_BIN}" >&2; exit 1; }

transcribe() {
  local target_file="${1:-${AUDIO_TMP}}"
  [[ -f "${target_file}" ]] || { echo "error: archivo de audio no existe" >&2; exit 1; }

  # Inferencia Whisper local en español con 4 hilos y contexto conversacional
  local raw_output
  raw_output="$("${WHISPER_BIN}" -m "${MODEL_BIN}" -f "${target_file}" -l es -t 4 --prompt "Hola Kz, ¿me oyes? Conversación en español con Kz." --no-prints 2>/dev/null)"

  # Limpiar timestamps [00:00:00.000 --> ...] y espacios extras
  local clean_text
  clean_text="$(printf '%s' "${raw_output}" | sed -E 's/\[[0-9:.]+ --> [0-9:.]+\]//g' | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')"

  if [[ -n "${clean_text}" ]]; then
    echo "${clean_text}"
    mkdir -p "${KZ_HOME}/presence"
    printf '%s\t%s\n' "$(date -Iseconds)" "${clean_text}" >> "${LOG_FILE}"
  else
    echo "(sin voz detectada)"
  fi
}

play_beep() {
  # Feedback auditivo sutil
  if command -v paplay >/dev/null 2>&1; then
    paplay /usr/share/sounds/freedesktop/stereo/bell.oga >/dev/null 2>&1 &
  fi
}

case "${1:-}" in
  --start)
    if [[ -f "${PID_FILE}" ]] && kill -0 "$(cat "${PID_FILE}")" 2>/dev/null; then
      echo "Ya se está grabando (PID $(cat "${PID_FILE}"))"
      exit 0
    fi
    rm -f "${AUDIO_TMP}" "${PID_FILE}"
    play_beep
    nohup arecord -q -f S16_LE -r 16000 -c 1 "${AUDIO_TMP}" >/dev/null 2>&1 &
    echo $! > "${PID_FILE}"
    echo "Grabando audio... (ejecuta 'kz-listen.sh --stop' para finalizar)"
    ;;
  --stop)
    if [[ -f "${PID_FILE}" ]]; then
      pid="$(cat "${PID_FILE}")"
      rm -f "${PID_FILE}"
      if kill -0 "${pid}" 2>/dev/null; then
        kill -INT "${pid}" 2>/dev/null || kill -TERM "${pid}" 2>/dev/null || true
        sleep 0.3
      fi
    fi
    play_beep
    if [[ ! -f "${AUDIO_TMP}" || $(stat -c%s "${AUDIO_TMP}" 2>/dev/null || echo 0) -lt 1000 ]]; then
      echo "(sin audio grabado)"
      exit 0
    fi
    transcribe "${AUDIO_TMP}"
    ;;
  --file)
    shift
    [[ $# -ge 1 ]] || { echo "uso: $0 --file <archivo.wav>" >&2; exit 1; }
    transcribe "$1"
    ;;
  *)
    seconds="${1:-8}"
    if ! [[ "${seconds}" =~ ^[0-9]+$ ]]; then
      echo "uso: $0 [segundos | --start | --stop | --file ruta]" >&2
      exit 1
    fi
    echo "Escuchando durante ${seconds} segundos..."
    play_beep
    nohup arecord -q -f S16_LE -r 16000 -c 1 "${AUDIO_TMP}" >/dev/null 2>&1 &
    REC_PID=$!
    sleep "${seconds}"
    kill -INT "${REC_PID}" 2>/dev/null || kill -TERM "${REC_PID}" 2>/dev/null || true
    sleep 0.2
    play_beep
    echo -n "Kz escuchó: "
    transcribe "${AUDIO_TMP}"
    ;;
esac
