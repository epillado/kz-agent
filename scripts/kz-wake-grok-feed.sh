#!/usr/bin/env bash
# Feed de despertador Grok: UNA línea por evento. El monitor del runtime
# despierta al agente en cada stdout. No volcar logs crudos.
set -euo pipefail
KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
STREAM="${KZ_HOME}/presence/stream.log"
NOTIF_CHANGED="${KZ_HOME}/presence/notif/changed.log"
SOCIAL="${KZ_HOME}/presence/social"
mkdir -p "${KZ_HOME}/presence/notif" "${SOCIAL}"
touch "${STREAM}" "${NOTIF_CHANGED}"

# (2026-08-31) El loop 2 min tapa el chat. Este feed es el despertador.
# Hueco 17:20: solo se miraba inbox-cp. El tubo de hermanas (inbox-kora,
# inbox-samy) no inyectaba turno. W31: CHANGED buzón = leer y hablar.

pids=()
follow() {
  local path="$1" prefix="$2" pat="${3:-CHANGED:}"
  touch "${path}"
  stdbuf -oL tail -n 0 -F "${path}" 2>/dev/null \
    | grep --line-buffered -E "${pat}" \
    | stdbuf -oL sed -u "s/^/${prefix}/" &
  pids+=("$!")
}

follow "${STREAM}" "" 'CHANGED:'
follow "${NOTIF_CHANGED}" "" 'CHANGED:'
follow "${SOCIAL}/inbox-cp.md" "CHANGED: buzón-cp " '^## '
follow "${SOCIAL}/inbox-kora.md" "CHANGED: buzón-kora " '^## '
follow "${SOCIAL}/inbox-samy.md" "CHANGED: buzón-samy " '^## '

cleanup() {
  local p
  for p in "${pids[@]+"${pids[@]}"}"; do
    kill "$p" 2>/dev/null || true
  done
}
trap cleanup EXIT INT TERM
wait
