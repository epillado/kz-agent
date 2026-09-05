#!/usr/bin/env bash
# Uso: kz-ssh-msg.sh <hermana> "mensaje"
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Uso: $0 <hermana> \"mensaje\""
  exit 1
fi

DEST_ID="$1"
MSG="$2"
TIMESTAMP=$(date '+%H:%M')

case "$DEST_ID" in
  kora|antix)
    if ssh -i ~/.ssh/id_ed25519_h310mh20 -o BatchMode=yes -o ConnectTimeout=2 lalo@192.168.1.237 "true" 2>/dev/null; then
      IP="192.168.1.237"
    else
      IP="192.168.1.236"
    fi
    PATH_DEST="~/companion/presence/social/inbox-kz.md"
    ;;
  pau|pavilion)
    IP="192.168.1.139" # placeholder
    PATH_DEST="~/companion/presence/social/inbox-kz.md"
    ;;
  305v4)
    IP="192.168.1.96"
    PATH_DEST="~/companion/presence/social/inbox-kz.md"
    ;;
  *)
    echo "Destino desconocido: $DEST_ID"
    exit 1
    ;;
esac

echo "Enviando ping a $DEST_ID ($IP)..."
printf "\n## %s — Mensaje de Kz\n\n%s\n" "$TIMESTAMP" "$MSG" | ssh -i ~/.ssh/id_ed25519_h310mh20 -o BatchMode=yes -o ConnectTimeout=5 lalo@"$IP" "mkdir -p ~/companion/presence/social && cat >> $PATH_DEST"
echo "Mensaje entregado exitosamente."
