#!/usr/bin/env bash
# Uso: kz-reply-lalo.sh "mensaje"
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 \"mensaje\""
  exit 1
fi

MSG="$*"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
OUTBOX="/home/lalo/kz/presence/social/outbox-lalo.md"

mkdir -p "$(dirname "$OUTBOX")"
printf "\n## %s — Respuesta de Kz\n\n%s\n" "$TIMESTAMP" "$MSG" >> "$OUTBOX"

# Intento KDE Connect si el cel está disponible
RENO_ID="1359e6af862344c9a9e97c72fdfbdc67"
if kdeconnect-cli -a --id-only 2>/dev/null | grep -q "$RENO_ID"; then
  kdeconnect-cli --device "$RENO_ID" --ping-msg "Kz: $MSG" 2>/dev/null || true
fi

echo "Respuesta registrada en $OUTBOX"
