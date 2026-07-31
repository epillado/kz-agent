#!/usr/bin/env bash
# Helper para el agente: tras escribir comentario en chat, manda tray con personalidad.
# Uso:
#   kz-presence-respond.sh say "Tu comentario corto para el tray"
#   kz-presence-respond.sh terminal
#   kz-presence-respond.sh terminal "Pista corta"
#   kz-presence-respond.sh clear     # marca pending como atendido
set -euo pipefail

KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
PENDING="${KZ_HOME}/presence/pending.md"
STATE_DIR="${KZ_HOME}/presence"

cmd="${1:-}"
shift || true

case "${cmd}" in
  say)
    text="${*:-Oye…}"
    "${KZ_HOME}/scripts/kz-nudge.sh" --say "${text}"
    ;;
  terminal)
    pista="${*:-Te dejé un comentario en la terminal de Grok (Kz). Voltea a ver.}"
    "${KZ_HOME}/scripts/kz-nudge.sh" --terminal "${pista}"
    ;;
  clear)
    if [[ -f "${PENDING}" ]]; then
      {
        echo
        echo "---"
        echo
        echo "**atendido:** $(date -Iseconds)"
      } >> "${PENDING}"
      mv -f "${PENDING}" "${STATE_DIR}/pending.last.md"
    fi
    rm -f "${STATE_DIR}/pending.ts"
    echo "pending cleared"
    ;;
  *)
    echo "uso: $0 say <texto> | terminal [pista] | clear" >&2
    exit 2
    ;;
esac
