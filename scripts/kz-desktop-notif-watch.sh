#!/usr/bin/env bash
# Wrapper del watcher de notificaciones de escritorio (Slack, etc.)
set -euo pipefail
KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
export KZ_HOME
exec python3 "${KZ_HOME}/scripts/kz-desktop-notif-watch.py" "$@"
