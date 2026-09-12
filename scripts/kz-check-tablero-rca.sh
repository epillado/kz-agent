#!/usr/bin/env bash
# kz-check-tablero-rca.sh — Healthcheck ligero del endpoint público del tablero RCA
set -euo pipefail

URL="https://protein-diversity-emphasis-silicon.trycloudflare.com"

if ! curl -sf -o /dev/null -u 'cognitio:SeconRca2026!' "${URL}/"; then
    MSG="[ALERTA] Tablero RCA no responde (HTTP error): ${URL}"
    echo -e "$(date '+%Y-%m-%dT%H:%M:%S%z')\timportant\tKz\tTableroRCA\t${MSG}" >> /home/lalo/kz/presence/notif/stream.log
    exit 1
fi
