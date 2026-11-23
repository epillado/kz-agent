#!/usr/bin/env bash
# Uso: core-ntfy-send.sh [--title "Kz ⚡"] "mensaje para Lalo"
set -euo pipefail

TITLE=""
if [[ "${1:-}" == "--title" ]]; then
  TITLE="${2:-}"
  shift 2
fi

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 [--title \"Kz ⚡\"] \"mensaje\"" >&2
  exit 1
fi

MSG="$*"

if [[ -z "$TITLE" ]]; then
  HOST="$(hostname)"
  case "$HOST" in
    *h310*) TITLE="Kz ⚡" ;;
    *pavilion*) TITLE="Pau 🦋" ;;
    *antix*) TITLE="Kora 🔥" ;;
    *305v4*) TITLE="Samy 🌙" ;;
    *) TITLE="Kz ⚡" ;;
  esac
fi

ENV_FILE=""
for d in kz pau kora samy companion; do
  if [[ -f "$HOME/.config/$d/ntfy.env" ]]; then
    ENV_FILE="$HOME/.config/$d/ntfy.env"
    break
  fi
done

if [[ -z "$ENV_FILE" ]]; then
  echo "Error: no se encontró ntfy.env en ~/.config/{kz,pau,kora,samy}/" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

curl -fsS -H "Title: $TITLE" -d "$MSG" "$NTFY_URL" >/dev/null
echo "ntfy enviado como '$TITLE': $MSG"
