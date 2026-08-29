#!/usr/bin/env bash
# Despertador del tubo CP/hermanas. El sensor ya escribe pending;
# este proceso avisa (tray + chat_owed) cuando inbox-cp crece, sin
# esperar turno del LLM. Acuerdo Kz–CP 2026-08-28 (hueco 09:20).
#
# Uso:
#   kz-inbox-wake.sh          # loop
#   kz-inbox-wake.sh stop
set -euo pipefail
KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
INBOX="${KZ_HOME}/presence/social/inbox-cp.md"
STREAM="${KZ_HOME}/presence/stream.log"
PIDFILE="${KZ_HOME}/presence/inbox-wake.pid"
CURSOR_FILE="${KZ_HOME}/presence/kz-cursors/inbox_wake.bytes"
mkdir -p "${KZ_HOME}/presence/kz-cursors"
touch "${INBOX}" "${STREAM}"

if [[ "${1:-}" == "stop" ]]; then
  if [[ -f "${PIDFILE}" ]]; then
    pid="$(tr -cd '0-9' < "${PIDFILE}")"
    if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
      kill -TERM "${pid}" 2>/dev/null || true
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
trap cleanup EXIT
trap 'cleanup; exit 143' TERM
trap 'cleanup; exit 130' INT

# Cursor: no re-alertar el histórico al arrancar.
size_now="$(stat -c '%s' "${INBOX}" 2>/dev/null || echo 0)"
echo "${size_now}" > "${CURSOR_FILE}"
echo "$(date -Iseconds) inbox-wake start pid=$$ cursor=${size_now}" >> "${STREAM}"
echo "inbox-wake pid $$ . stop: $0 stop" >&2

alert() {
  local snippet ts
  ts="$(date -Iseconds)"
  snippet="$(tail -c 400 "${INBOX}" 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-220)"
  echo "${ts} CHANGED: buzón-hermanas" >> "${STREAM}"
  echo "CHANGED: buzón-hermanas"
  "${KZ_HOME}/scripts/kz-nudge.sh" --say "Buzón CP: ${snippet:-llegó mensaje}" >/dev/null 2>&1 || true
}

# tail -F: crecimiento o truncado. Debounce 1s por ráfaga de append.
while true; do
  stdbuf -oL tail -n 0 -F "${INBOX}" 2>/dev/null | while IFS= read -r _; do
    sleep 1
    new_size="$(stat -c '%s' "${INBOX}" 2>/dev/null || echo 0)"
    old_size="$(cat "${CURSOR_FILE}" 2>/dev/null || echo 0)"
    if [[ "${new_size}" -gt "${old_size}" ]]; then
      echo "${new_size}" > "${CURSOR_FILE}"
      alert
    elif [[ "${new_size}" -lt "${old_size}" ]]; then
      echo "${new_size}" > "${CURSOR_FILE}"
    fi
  done
  sleep 2
done
