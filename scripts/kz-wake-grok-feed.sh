#!/usr/bin/env bash
# Feed de despertador Grok: UNA línea por evento. El monitor del runtime
# despierta al agente en cada stdout. No volcar logs crudos.
set -euo pipefail
KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
STREAM="${KZ_HOME}/presence/stream.log"
INBOX="${KZ_HOME}/presence/social/inbox-cp.md"
touch "${STREAM}" "${INBOX}"

emit() { stdbuf -oL printf '%s\n' "$1"; }

# Dos colas, una línea de evento cada una. grep line-buffered: sin esto el pipe se duerme.
stdbuf -oL tail -n 0 -F "${STREAM}" 2>/dev/null \
  | grep --line-buffered -E 'CHANGED:' &
p1=$!

stdbuf -oL tail -n 0 -F "${INBOX}" 2>/dev/null \
  | grep --line-buffered -E '^## ' \
  | stdbuf -oL sed -u 's/^/CHANGED: buzón-hermanas /' &
p2=$!

cleanup() { kill "$p1" "$p2" 2>/dev/null || true; }
trap cleanup EXIT INT TERM
wait
