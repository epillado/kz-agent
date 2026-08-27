#!/usr/bin/env bash
# 20-20-20: escribe CHANGED y avisa a Lalo sin esperar a que el LLM despierte.
# El chat de la sesión sigue siendo deuda (chat_owed) para cuando Kz sí despierte.
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
  echo "${ts} CHANGED: timer-ojos" >>"$STREAM"
  if en_call; then
    # En call: popup, sin beep por altavoces. Chat igual se debe.
    notify-send -u normal -a "Kz" -i dialog-information "Kz" "Pausa de ojos. 20-20-20." 2>/dev/null || true
    cat > "${KZ_HOME}/presence/chat_owed.md" <<EOF
# Chat owed — terminal de Grok (Kz)

- **cuando:** ${ts}
- **origen:** kz-ojos-loop
- **título tray:** Kz
- **cuerpo:** Pausa de ojos. 20-20-20.
- **estado:** awaiting_chat_in_terminal
EOF
  else
    "${KZ_HOME}/scripts/kz-nudge.sh" --say "Pausa de ojos. 20-20-20. Mira lejos." >/dev/null 2>&1 || true
  fi
}

while true; do
  sleep 1200
  tick
done
