#!/usr/bin/env bash
# Despertador Agy / Claude / Codex: espera UN evento CHANGED/buzón y sale con 0 sin bloquear subshells.
set -euo pipefail
KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 "${KZ_HOME}/scripts/kz-wake-once.py"
