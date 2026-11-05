#!/usr/bin/env bash
# Sensor del canal Kalys en Drive. No despierta al modelo en cada vuelta.
# Cada 3 minutos lista el PKM. Solo si un archivo cambia, agrega un
# encabezado ## en presence/social/inbox-kalys.md. Ese archivo ya lo
# sigue el feed de Grok. Prohibido convertirlo en cron */2 del LLM.
#
# Uso: kz-drive-kalys-watch.sh [stop]
set -euo pipefail
KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
PIDFILE="${KZ_HOME}/presence/drive-kalys-watch.pid"
PY="${KZ_HOME}/scripts/kz-drive-kalys-watch.py"

if [[ "${1:-}" == "stop" ]]; then
  if [[ -f "${PIDFILE}" ]]; then
    pid="$(tr -cd '0-9' < "${PIDFILE}")"
    if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
      kill -TERM "${pid}" 2>/dev/null || true
      i=0
      while kill -0 "${pid}" 2>/dev/null && (( i < 25 )); do
        sleep 0.2
        i=$((i + 1))
      done
      if kill -0 "${pid}" 2>/dev/null; then
        kill -KILL "${pid}" 2>/dev/null || true
      fi
    fi
    rm -f "${PIDFILE}"
  fi
  echo "stopped drive-kalys-watch"
  exit 0
fi

if [[ -f "${PIDFILE}" ]] && kill -0 "$(tr -cd '0-9' < "${PIDFILE}")" 2>/dev/null; then
  echo "ya corre drive-kalys-watch pid=$(tr -cd '0-9' < "${PIDFILE}")"
  exit 0
fi

echo $$ > "${PIDFILE}"
exec python3 -u "${PY}"
