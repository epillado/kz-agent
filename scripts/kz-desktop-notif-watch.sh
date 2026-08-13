#!/usr/bin/env bash
# Wrapper del watcher de notificaciones de escritorio (Slack, etc.)
set -euo pipefail
KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
export KZ_HOME
if [[ "${1:-}" == "stop" ]]; then
  exec python3 "${KZ_HOME}/scripts/kz-desktop-notif-watch.py" stop
fi

# Iniciar desacoplado de la TTY con setsid si no viene con stop
exec setsid python3 -u "${KZ_HOME}/scripts/kz-desktop-notif-watch.py" "$@" &
