#!/usr/bin/env bash
# kz-pkm-radar.sh — depósito Kz → CP en playbook/PKM/ (único canal que el CP lee).
#
# El sensor de Slack/desktop NO escribe PKM. Este script (o el agente) DEBE
# depositar Acción CP (Josué/cliente/SE/Meet/bloqueo/VoBo/decisión/P0).
# Silencio en PKM ≠ calma: es ceguera del canal (incidente 2026-08-12).
#
# Uso:
#   kz-pkm-radar.sh "título corto" "cuerpo markdown (una línea o \n)"
#   kz-pkm-radar.sh "título" <<'EOF'
#   cuerpo multilinea
#   EOF
#   kz-pkm-radar.sh --file path.md     # append contenido de archivo
#   kz-pkm-radar.sh --path             # imprime path del radar del día
#   kz-pkm-radar.sh --ack "texto"      # nota de estado/ack al CP
#
# Env:
#   KZ_PLAYBOOK=…   override playbook
set -euo pipefail

KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"

if [[ -n "${KZ_PLAYBOOK:-}" ]]; then
  PLAYBOOK="${KZ_PLAYBOOK}"
elif [[ -d "${HOME}/Workspace/playbook" ]]; then
  PLAYBOOK="${HOME}/Workspace/playbook"
elif [[ -d "/mnt/DatosLinux/Workspace/playbook" ]]; then
  PLAYBOOK="/mnt/DatosLinux/Workspace/playbook"
else
  PLAYBOOK="${HOME}/Workspace/playbook"
fi

DAY="$(date +%Y%m%d)"
TS="$(date -Iseconds)"
# Hora de reloj vs filesystem: estampar ambas si se pide --clock
CLOCK_LINE="reloj=$(date '+%Y-%m-%d %H:%M:%S %z')"

PKM_DIR="${PLAYBOOK}/PKM"
RADAR="${PKM_DIR}/${DAY}-GOV-radar_slack_kz.md"
mkdir -p "${PKM_DIR}"

ensure_header() {
  if [[ ! -f "${RADAR}" ]]; then
    cat > "${RADAR}" <<EOF
---
tipo: transitorio
fuente: kz-radar
fecha: ${DAY:0:4}-${DAY:4:2}-${DAY:6:2}
canal: slack+desktop
tema: radar hot Kz → CP (append del día)
---

# Radar Kz → CP — ${DAY:0:4}-${DAY:4:2}-${DAY:6:2}

> Canal único de handoff Kz→CP. Append-only por evento gordo.
> Sensor tray ≠ depósito. Sin nota aquí, el CP no ve el evento.

EOF
  fi
}

if [[ "${1:-}" == "--path" ]]; then
  echo "${RADAR}"
  exit 0
fi

if [[ "${1:-}" == "--ack" ]]; then
  shift
  body="${*:-}"
  ensure_header
  {
    echo
    echo "---"
    echo
    echo "## ACK / estado canal — ${TS}"
    echo
    echo "- **${CLOCK_LINE}**"
    echo "- **playbook:** \`${PLAYBOOK}\` (canon de vigilancia Kz)"
    echo
    echo "${body}"
    echo
  } >> "${RADAR}"
  # touch probe for clock check
  stat -c 'fs_mtime=%y' "${RADAR}" >> "${RADAR}.clock" 2>/dev/null || true
  echo "pkm-ack: ${RADAR}"
  exit 0
fi

if [[ "${1:-}" == "--file" ]]; then
  src="${2:-}"
  [[ -f "$src" ]] || { echo "error: no file $src" >&2; exit 1; }
  ensure_header
  {
    echo
    echo "---"
    echo
    echo "## Import — ${TS}"
    echo
    echo "- **${CLOCK_LINE}**"
    echo
    cat "$src"
    echo
  } >> "${RADAR}"
  echo "pkm-append-file: ${RADAR}"
  exit 0
fi

title="${1:-}"
if [[ -z "$title" ]]; then
  echo "uso: $0 \"título\" \"cuerpo\" | $0 \"título\" <<EOF ..." >&2
  exit 1
fi
shift

if [[ -n "${1:-}" ]]; then
  body="$*"
else
  body="$(cat)"
fi

ensure_header
{
  echo
  echo "---"
  echo
  echo "## ${title}"
  echo
  echo "- **cuando_deposito:** ${TS}"
  echo "- **${CLOCK_LINE}**"
  echo "- **estado:** Acción CP (handoff Kz)"
  echo
  echo "${body}"
  echo
} >> "${RADAR}"

echo "pkm-append: ${RADAR}"
