#!/usr/bin/env bash
# Push-to-Talk para Kz (Toggle ON / Toggle OFF)
# Diseñado para asignarse a un atajo de teclado global en KDE (ej. ScrollLock, Pause o F12).
#
# Comportamiento:
# 1. Presionas una vez -> Suena bip + Notificación "Kz escuchando..." + Empieza a grabar mic.
# 2. Presionas de nuevo -> Suena bip + Transcribe con Whisper + Copia al portapapeles + Notificación con el texto.
#
set -euo pipefail

KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
WHISPER_BIN="${KZ_HOME}/tools/whisper.cpp/build/bin/whisper-cli"
MODEL_BIN="${KZ_HOME}/tools/whisper.cpp/models/ggml-small.bin"
[[ -f "${MODEL_BIN}" ]] || MODEL_BIN="${KZ_HOME}/tools/whisper.cpp/models/ggml-base.bin"

AUDIO_FILE="/tmp/kz-ptt-mic.wav"
PID_FILE="/tmp/kz-ptt.pid"
LOG_FILE="${KZ_HOME}/presence/listen.log"

play_sound() {
  local sound="$1"
  if command -v paplay >/dev/null 2>&1 && [[ -f "/usr/share/sounds/freedesktop/stereo/${sound}.oga" ]]; then
    paplay "/usr/share/sounds/freedesktop/stereo/${sound}.oga" >/dev/null 2>&1 &
  fi
}

if [[ ! -f "${PID_FILE}" ]]; then
  # ESTADO: INICIAR GRABACIÓN
  rm -f "${AUDIO_FILE}"
  play_sound "bell"
  pw-record --rate 16000 --channels 1 "${AUDIO_FILE}" >/dev/null 2>&1 &
  echo $! > "${PID_FILE}"
  notify-send -t 3000 -u low -i audio-input-microphone "🎤 Kz escuchando..." "Habla ahora. Presiona la tecla para enviar." 2>/dev/null || true
  echo "PTT: Grabando..."
else
  # ESTADO: DETENER Y TRANSCRIBIR
  rec_pid="$(cat "${PID_FILE}")"
  rm -f "${PID_FILE}"
  if kill -0 "${rec_pid}" 2>/dev/null; then
    kill -INT "${rec_pid}" 2>/dev/null || true
    sleep 0.2
  fi
  play_sound "complete"

  if [[ -f "${AUDIO_FILE}" ]]; then
    raw_output="$("${WHISPER_BIN}" -m "${MODEL_BIN}" -f "${AUDIO_FILE}" -l es -t 4 --prompt "Hola Kz, ¿me oyes? Conversación en español con Kz." --no-prints 2>/dev/null)"
    clean_text="$(printf '%s' "${raw_output}" | sed -E 's/\[[0-9:.]+ --> [0-9:.]+\]//g' | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')"

    if [[ -n "${clean_text}" ]]; then
      # Copiar al portapapeles de Wayland
      if command -v wl-copy >/dev/null 2>&1; then
        printf '%s' "${clean_text}" | wl-copy
      fi
      mkdir -p "${KZ_HOME}/presence"
      printf '%s\t%s\n' "$(date -Iseconds)" "${clean_text}" >> "${LOG_FILE}"
      notify-send -t 6000 -i audio-input-microphone "📝 Kz transcribió (copiado al portapapeles):" "${clean_text}" 2>/dev/null || true
      echo "PTT: ${clean_text}"
    else
      notify-send -t 3000 -i audio-input-microphone "Kz:" "No se detectó voz en la grabación." 2>/dev/null || true
      echo "PTT: (sin voz)"
    fi
  fi
fi
