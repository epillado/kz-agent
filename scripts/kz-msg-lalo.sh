#!/usr/bin/env bash
# Uso: kz-msg-lalo.sh "mensaje"
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 \"mensaje\""
  exit 1
fi

MSG="$*"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
INBOX="/home/lalo/kz/presence/social/inbox-lalo.md"

mkdir -p "$(dirname "$INBOX")"
printf "\n## %s — Mensaje de Lalo\n\n%s\n" "$TIMESTAMP" "$MSG" >> "$INBOX"
echo "Mensaje entregado a Kz en $INBOX"
