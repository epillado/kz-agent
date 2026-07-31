#!/usr/bin/env bash
# Estado del setup: dispositivo, latest, watch, dependencias
set -euo pipefail
# shellcheck source=/dev/null
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

echo "=== Kz cam status ==="
echo "KZ_HOME:     ${KZ_HOME}"
echo "DEVICE:      ${KZ_DEVICE}"
echo "RESOLUTION:  ${KZ_RESOLUTION}"
echo "FORMAT:      ${KZ_INPUT_FORMAT}"
echo

if [[ -e "${KZ_DEVICE}" ]]; then
  echo "device: exists"
  [[ -r "${KZ_DEVICE}" ]] && echo "  read:  yes" || echo "  read:  NO"
  [[ -w "${KZ_DEVICE}" ]] && echo "  write: yes" || echo "  write: NO"
else
  echo "device: MISSING"
fi

echo
echo "tools:"
for c in ffmpeg v4l2-ctl identify; do
  if command -v "$c" >/dev/null 2>&1; then
    echo "  $c: $(command -v "$c")"
  else
    echo "  $c: (no instalado)"
  fi
done

echo
if command -v v4l2-ctl >/dev/null 2>&1; then
  echo "v4l2 devices:"
  v4l2-ctl --list-devices 2>/dev/null || true
fi

echo
echo "latest:"
if [[ -f "${LATEST_JPG}" ]]; then
  ls -la "${LATEST_JPG}"
  [[ -f "${LATEST_META}" ]] && cat "${LATEST_META}"
else
  echo "  (aún no hay captura)"
fi

echo
PIDFILE="${WEBCAM_DIR}/watch.pid"
if [[ -f "${PIDFILE}" ]]; then
  pid="$(cat "${PIDFILE}")"
  if kill -0 "${pid}" 2>/dev/null; then
    echo "watch: RUNNING pid ${pid}"
  else
    echo "watch: pidfile huérfano (${pid})"
  fi
else
  echo "watch: stopped"
fi
