#!/usr/bin/env bash
# kz-slack-watch.sh — Demonio de monitoreo de canales, DMs y grupos de Slack para Kz
# Redirige CHANGED: slack ... a ~/kz/presence/stream.log para despertar a Grok vía kz-wake-grok-feed.sh
set -euo pipefail

KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
PIDFILE="${KZ_HOME}/presence/slack-watch.pid"
STREAM="${KZ_HOME}/presence/stream.log"
SCRIPT="${KZ_HOME}/scripts/kz-slack-frente-watch.py"

status() {
  if [[ -f "${PIDFILE}" ]]; then
    local pid
    pid="$(cat "${PIDFILE}" 2>/dev/null || true)"
    if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
      echo "slack-watch corriendo pid=${pid}"
      return 0
    fi
  fi
  echo "slack-watch no está corriendo"
  return 1
}

stop() {
  local pids
  pids="$(pgrep -f "${SCRIPT}" || true)"
  if [[ -n "${pids}" ]]; then
    echo "Deteniendo slack-watch (pids: ${pids})..."
    kill -TERM ${pids} 2>/dev/null || true
    sleep 0.5
    for p in ${pids}; do
      if kill -0 "$p" 2>/dev/null; then
        kill -KILL "$p" 2>/dev/null || true
      fi
    done
  fi
  rm -f "${PIDFILE}"
  echo "slack-watch detenido."
}

start() {
  if status >/dev/null 2>&1; then
    echo "slack-watch ya está activo."
    return 0
  fi
  stop >/dev/null 2>&1 || true
  mkdir -p "${KZ_HOME}/presence"
  touch "${STREAM}"
  echo "Arrancando slack-watch hacia stream.log..."
  setsid python3 -u "${SCRIPT}" >> "${STREAM}" 2>&1 &
  local pid="$!"
  echo "${pid}" > "${PIDFILE}"
  sleep 0.5
  if kill -0 "${pid}" 2>/dev/null; then
    echo "✅ slack-watch iniciado exitosamente (pid=${pid})."
  else
    echo "❌ Falló el arranque de slack-watch."
    rm -f "${PIDFILE}"
    return 1
  fi
}

case "${1:-start}" in
  start)  start ;;
  stop)   stop ;;
  status) status ;;
  restart)
    stop
    sleep 0.5
    start
    ;;
  *)
    echo "Uso: $0 {start|stop|status|restart}"
    exit 1
    ;;
esac
