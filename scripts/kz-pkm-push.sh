#!/usr/bin/env bash
# Empuja SOLO el radar de Kz del día. No es sync_notas (ese hace add -A).
#
# Día, CP en esta misma caja: no hace falta — el CP lee el disco.
# Noche / CP en otra máquina: sí. Sin esto el depósito vive solo aquí.
#
# Uso:
#   kz-pkm-push.sh          # radar del día
#   kz-pkm-push.sh --path   # imprime el archivo que empujaría
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
RADAR="${PLAYBOOK}/PKM/${DAY}-GOV-radar_slack_kz.md"

if [[ "${1:-}" == "--path" ]]; then
  echo "${RADAR}"
  exit 0
fi

[[ -f "${RADAR}" ]] || { echo "error: no existe ${RADAR}" >&2; exit 1; }
[[ -d "${PLAYBOOK}/.git" ]] || { echo "error: playbook no es repo git: ${PLAYBOOK}" >&2; exit 1; }

cd "${PLAYBOOK}"

rel="PKM/${DAY}-GOV-radar_slack_kz.md"
git add -- "${rel}"

if git diff --cached --quiet -- "${rel}"; then
  echo "pkm-push: nada nuevo en ${rel}"
  exit 0
fi

git commit -m "pkm: radar kz ${DAY}"
git pull --rebase --autostash origin main
git push origin main
echo "pkm-push: ${rel}"
