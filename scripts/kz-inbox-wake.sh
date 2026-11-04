#!/usr/bin/env bash
# Tray cuando crece cualquier tubo (inbox-*.md), sin esperar turno del LLM.
# No escribe el token CHANGED: el feed de Grok ya sigue esos archivos y
# una segunda línea despertaría el chat dos veces.
# Acuerdo Kz–CP 2026-08-28. Ampliado 2026-11-04: toda hermana, no solo el CP.
#
# Uso:
#   kz-inbox-wake.sh          # loop
#   kz-inbox-wake.sh stop
set -euo pipefail
KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
SOCIAL="${KZ_HOME}/presence/social"
STREAM="${KZ_HOME}/presence/stream.log"
PIDFILE="${KZ_HOME}/presence/inbox-wake.pid"
CURSOR_DIR="${KZ_HOME}/presence/kz-cursors"
mkdir -p "${CURSOR_DIR}" "${SOCIAL}"
touch "${STREAM}"

if [[ "${1:-}" == "stop" ]]; then
  if [[ -f "${PIDFILE}" ]]; then
    pid="$(tr -cd '0-9' < "${PIDFILE}")"
    if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
      kill -TERM "${pid}" 2>/dev/null || true
      pkill -TERM -P "${pid}" 2>/dev/null || true
      i=0
      while kill -0 "${pid}" 2>/dev/null && (( i < 25 )); do
        sleep 0.2
        i=$((i + 1))
      done
      if kill -0 "${pid}" 2>/dev/null; then
        kill -KILL "${pid}" 2>/dev/null || true
        sleep 0.2
      fi
    fi
    rm -f "${PIDFILE}"
  fi
  leftover="$(pgrep -f 'kz-inbox-wake.sh$' || true)"
  leftover="$(printf '%s\n' "${leftover}" | grep -v "^$$$" || true)"
  if [[ -n "${leftover}" ]]; then
    echo "error: inbox-wake SIGUE VIVO: ${leftover}" >&2
    exit 1
  fi
  echo "stopped inbox-wake (pgrep ok)"
  exit 0
fi

if [[ -f "${PIDFILE}" ]] && kill -0 "$(tr -cd '0-9' < "${PIDFILE}")" 2>/dev/null; then
  echo "error: ya corre inbox-wake pid=$(cat "${PIDFILE}"). stop primero." >&2
  exit 1
fi

echo $$ > "${PIDFILE}"
cleanup() { rm -f "${PIDFILE}"; }
trap 'cleanup; pkill -TERM -P $$ 2>/dev/null || true; exit 143' TERM
trap 'cleanup; pkill -TERM -P $$ 2>/dev/null || true; exit 130' INT
trap cleanup EXIT

declare -A watching=()

alert() {
  local path="$1" name="$2"
  local snippet heading ts mode
  ts="$(date -Iseconds)"
  heading="$(grep '^## ' "${path}" 2>/dev/null | tail -n 1 | tr -d '\r')"
  snippet="$(tail -c 280 "${path}" 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-180)"
  echo "${ts} inbox-wake: buzón-${name} ${heading}" >> "${STREAM}"
  mode="--terminal"
  if [[ -f "${KZ_HOME}/presence/context.md" ]] && grep -q '^\- \*\*en_call:\*\* no' "${KZ_HOME}/presence/context.md" \
     && [[ -f "${KZ_HOME}/presence/self.md" ]] && grep -Eq '^\- \*\*voz_activa:\*\* s[ií]' "${KZ_HOME}/presence/self.md"; then
    mode="--say"
  fi
  "${KZ_HOME}/scripts/kz-nudge.sh" ${mode} "Buzón ${name}: ${heading:-llegó mensaje}" >/dev/null 2>&1 || true
}

start_watch() {
  local path="$1"
  [[ -n "${watching[$path]:-}" ]] && return 0
  [[ -f "${path}" ]] || return 0
  local name cursor
  name="$(basename "${path}" .md)"
  name="${name#inbox-}"
  cursor="${CURSOR_DIR}/inbox_wake_${name}.bytes"
  stat -c '%s' "${path}" > "${cursor}" 2>/dev/null || echo 0 > "${cursor}"
  watching["${path}"]=1
  (
    stdbuf -oL tail -n 0 -F "${path}" 2>/dev/null | while IFS= read -r _; do
      sleep 1
      local new old
      new="$(stat -c '%s' "${path}" 2>/dev/null || echo 0)"
      old="$(cat "${cursor}" 2>/dev/null || echo 0)"
      if [[ "${new}" -gt "${old}" ]]; then
        echo "${new}" > "${cursor}"
        alert "${path}" "${name}"
      elif [[ "${new}" -lt "${old}" ]]; then
        echo "${new}" > "${cursor}"
      fi
    done
  ) &
}

echo "$(date -Iseconds) inbox-wake start pid=$$ tubos=inbox-*.md" >> "${STREAM}"
echo "inbox-wake pid $$ . stop: $0 stop" >&2

while true; do
  shopt -s nullglob
  for f in "${SOCIAL}"/inbox-*.md; do
    start_watch "${f}"
  done
  shopt -u nullglob
  sleep 15
done
