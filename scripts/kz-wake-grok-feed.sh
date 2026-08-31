#!/usr/bin/env bash
# Feed de despertador Grok: UNA línea por evento. El monitor del runtime
# despierta al agente en cada stdout. No volcar logs crudos.
set -euo pipefail
KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
STREAM="${KZ_HOME}/presence/stream.log"
INBOX="${KZ_HOME}/presence/social/inbox-cp.md"
NOTIF_CHANGED="${KZ_HOME}/presence/notif/changed.log"
mkdir -p "${KZ_HOME}/presence/notif" "${KZ_HOME}/presence/social"
touch "${STREAM}" "${INBOX}" "${NOTIF_CHANGED}"

# Tres colas, una línea de evento cada una. grep line-buffered: sin esto el pipe se duerme.
# (2026-08-31) El loop 2 min de Grok tapa el chat: el despertador es ESTE feed, no un scheduler.
stdbuf -oL tail -n 0 -F "${STREAM}" 2>/dev/null \
  | grep --line-buffered -E 'CHANGED:' &
p1=$!

stdbuf -oL tail -n 0 -F "${INBOX}" 2>/dev/null \
  | grep --line-buffered -E '^## ' \
  | stdbuf -oL sed -u 's/^/CHANGED: buzón-hermanas /' &
p2=$!

stdbuf -oL tail -n 0 -F "${NOTIF_CHANGED}" 2>/dev/null \
  | grep --line-buffered -E 'CHANGED:' &
p3=$!

cleanup() { kill "$p1" "$p2" "$p3" 2>/dev/null || true; }
trap cleanup EXIT INT TERM
wait
