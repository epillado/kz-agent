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
# Hueco 17:20: solo se miraba inbox-cp. Hueco 2026-11-04 15:01: la lista
# fija (cp, kora, samy) dejó fuera a Pau. Lalo: no puede volver a pasar.
# Se sigue todo inbox-*.md, y un archivo nuevo entra en el siguiente barrido.
# El barrido no escribe nada: solo un encabezado nuevo despierta.

declare -A seen=()
pids=()

follow() {
  local path="$1" prefix="$2" pat="${3:-CHANGED:}"
  # stream.log → unified.log. tail -F y tail -f sobre el symlink no ven
  # los append al destino (sordo a Slack desde el arranque, 2026-11-05).
  if [[ -L "${path}" ]]; then
    path="$(readlink -f "${path}")"
  fi
  touch "${path}"
  stdbuf -oL tail -n 0 -F "${path}" 2>/dev/null \
    | grep --line-buffered -E "${pat}" \
    | stdbuf -oL sed -u "s/^/${prefix}/" &
  pids+=("$!")
}

start_inbox() {
  local path="$1" name
  [[ -n "${seen[$path]:-}" ]] && return 0
  [[ -f "${path}" ]] || return 0
  name="$(basename "${path}" .md)"
  name="${name#inbox-}"
  seen["${path}"]=1
  follow "${path}" "CHANGED: buzón-${name} " '^## '
}

scan_inboxes() {
  local f
  shopt -s nullglob
  for f in "${SOCIAL}"/inbox-*.md; do
    start_inbox "${f}"
  done
  shopt -u nullglob
}

follow "${STREAM}" "" 'CHANGED:'
follow "${NOTIF_CHANGED}" "" 'CHANGED:'
scan_inboxes

cleanup() {
  local p
  for p in "${pids[@]+"${pids[@]}"}"; do
    kill "${p}" 2>/dev/null || true
  done
}
trap cleanup EXIT INT TERM

# El sleep no es un despertador: no imprime. Solo adopta un inbox nuevo.
while true; do
  sleep 20
  scan_inboxes
done
