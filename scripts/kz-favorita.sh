#!/usr/bin/env bash
# Marca una forma de Kz para que viaje en git (add -f).
# No des-ignora toda presence/me/. Solo ese archivo + línea en forma.md.
#
#   kz-favorita.sh <jpg> [nota]
set -euo pipefail
KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
INDEX="${KZ_HOME}/presence/forma.md"
src="${1:-}"
note="${*:2}"
[[ -n "${src}" && -f "${src}" ]] || { echo "uso: $0 <jpg> [nota]" >&2; exit 1; }
[[ "${src}" == /* ]] || src="$(pwd)/${src}"

cd "${KZ_HOME}"
rel="${src#${KZ_HOME}/}"
git add -f -- "${rel}"
if [[ -f "${INDEX}" ]] && ! grep -q "${rel}" "${INDEX}"; then
  ts="$(date '+%Y-%m-%d')"
  echo "| \`${rel}\` | ${ts} | ${note:-favorita} |" >> "${INDEX}"
fi
echo "favorita en git: ${rel}"
echo "queda en origin al próximo push de kz-agent."
