#!/usr/bin/env bash
# 20-20-20: globo + disco. NO despierta al LLM (W42 / 2026-09-08).
# Sin CHANGED. Sin chat_owed. Si hay sesión ya abierta y Lalo dice POC, se acusa ahí.
set -euo pipefail
export DISPLAY="${DISPLAY:-:0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
STREAM="${KZ_HOME}/presence/stream.log"
CTX="${KZ_HOME}/presence/context.md"
mkdir -p "${KZ_HOME}/presence"
echo $$ > "${KZ_HOME}/presence/ojos-loop.pid"
trap 'rm -f "${KZ_HOME}/presence/ojos-loop.pid"' EXIT

en_call() {
  [[ -f "$CTX" ]] && grep -qE '^\- \*\*en_call:\*\* yes' "$CTX"
}

tick() {
  local ts
  ts="$(date -Iseconds)"
  # Log de host, sin la palabra CHANGED (el feed de Grok despierta con eso).
  echo "${ts} ojos: 20-20-20 (tray; sin wake)" >>"$STREAM"
  if en_call; then
    notify-send -u normal -a "Kz" -i dialog-information "Kz" "Pausa de ojos. 20-20-20." 2>/dev/null || true
  else
    KZ_NUDGE_NO_CHAT_OWED=1 "${KZ_HOME}/scripts/kz-nudge.sh" --say "Pausa de ojos. 20-20-20. Mira lejos." >/dev/null 2>&1 || true
  fi
}

while true; do
  sleep 1200
  tick
done
