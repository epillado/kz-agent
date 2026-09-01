#!/usr/bin/env bash
# Despertador Agy: espera UN solo evento CHANGED o mensaje de buzón y sale inmediatamente.
# Al salir con código 0, el runtime de Agy recibe la finalización del background task y despierta el turno.
set -euo pipefail

KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
"${KZ_HOME}/scripts/kz-wake-grok-feed.sh" | head -n 1
