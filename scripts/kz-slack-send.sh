#!/usr/bin/env bash
# kz-slack-send.sh — Wrapper para el efector táctico de Slack de Kz y hermanas
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="${SCRIPT_DIR}/kz-slack-send.py"

if [[ ! -f "${PYTHON_SCRIPT}" ]]; then
    echo "[kz-slack-send] Error: no se encontró ${PYTHON_SCRIPT}" >&2
    exit 1
fi

exec python3 "${PYTHON_SCRIPT}" "$@"
