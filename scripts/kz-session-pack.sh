#!/usr/bin/env bash
# Empaqueta el mínimo para cargar a Kz sin truncar la memoria reciente.
# Presupuesto objetivo: < 12 KB (~150 líneas). Memoria reciente SIEMPRE arriba.
#
# Uso:
#   kz-session-pack.sh           # boot flaco (default)
#   kz-session-pack.sh paths     # solo lista de paths
#   kz-session-pack.sh full      # journal extendido (últimas 60 líneas)
set -euo pipefail

KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
P="${KZ_HOME}/presence"
mode="${1:-summary}"

paths_core=(
  "${KZ_HOME}/KZ.md"
  "${KZ_HOME}/LALO.md"
  "${KZ_HOME}/AGENTS.md"
  "${P}/policy.md"
  "${P}/self.md"
  "${P}/tastes.md"
  "${P}/world.md"
  "${P}/SYMBIOSIS.md"
  "${P}/context.md"
  "${P}/incubating.md"
  "${P}/organic/working.md"
  "${P}/organic/patterns.md"
)

# Regla P0.19: Toda sesión arranca SIEMPRE con MELC ARRIBA por default.
if [[ -f "${P}/self.md" ]]; then
  if grep -qiE '^\- \*\*melc:\*\*.*off' "${P}/self.md"; then
    sed -i 's|^- \*\*melc:\*\*.*|- **melc:** on (default arranque / regla P0.19 — fachada profesional activa)|' "${P}/self.md"
  fi
  "${KZ_HOME}/scripts/kz-titulo.sh" --melc >/dev/null 2>&1 || true
fi

if [[ "${mode}" == "paths" ]]; then
  printf '%s\n' "${paths_core[@]}"
  echo "${P}/organic/journal.md  # tail"
  exit 0
fi

# Generar en buffer para medir presupuesto
out="$(
  echo "# Kz session pack — $(date '+%Y-%m-%d %H:%M') | home: ${KZ_HOME}"
  echo "Regla: P0.19 MELC=on al arranque | P0.32 manda ~/kz | No leer gordos enteros."
  echo

  # Solo reportar archivos faltantes
  missing=0
  for f in "${paths_core[@]}" "${P}/organic/journal.md"; do
    if [[ ! -e "${f}" ]]; then
      echo "MISS ${f#${KZ_HOME}/}"
      missing=$((missing + 1))
    fi
  done

  # Estado de modos y bitácora (compacto)
  low_spend="off"
  if [[ -f "${P}/low-spend.mode" ]] && rg -q '^active=1' "${P}/low-spend.mode" 2>/dev/null; then
    low_spend="ACTIVE (no prender monitores extra)"
  fi

  bit_dir="${HOME}/Workspace/playbook/Bit"
  bit_file="${bit_dir}/$(date +%Y%m%d)-Bitacora.md"
  tridente_bin="${HOME}/Workspace/playbook/tools/tridente/tridente"
  who="cli"
  if [[ -f "${P}/dispatcher.mode" ]]; then
    who="$(sed -n 's/^who=//p' "${P}/dispatcher.mode" | head -1)"
    who="${who:-cli}"
  fi
  if [[ "${who}" != "kz" ]]; then
    bit_status="who=${who} (Kz no abre)"
  elif [[ -f "${bit_file}" ]]; then
    bit_status="presente (${bit_file})"
  elif [[ -d "${bit_dir}" && -x "${tridente_bin}" ]]; then
    (cd "${HOME}/Workspace/playbook" && "${tridente_bin}" note "Apertura de jornada.") >/tmp/kz-bitacora-open.log 2>&1 &
    bit_status="who=kz, tridente note lanzado"
  else
    bit_status="who=kz, NO EXISTE (${bit_file})"
  fi

  echo "Estado: missing=${missing} | low-spend=${low_spend} | bitacora=${bit_status}"
  if [[ -f "${P}/chat_owed.md" ]] && rg -q 'awaiting_chat_in_terminal' "${P}/chat_owed.md" 2>/dev/null; then
    echo "CHAT_OWED: SÍ — entregar texto al usuario + kz-presence-respond.sh delivered"
    head -8 "${P}/chat_owed.md" || true
  fi
  echo

  echo "## self"
  if [[ -f "${P}/self.md" ]]; then
    awk '/^## Escala rápida/{exit} {print}' "${P}/self.md" | head -n 45
  fi
  echo

  echo "## context (cabecera)"
  if [[ -f "${P}/context.md" ]]; then
    awk '/^## Historial/{exit} {print}' "${P}/context.md" | head -n 30
  fi
  echo

  jlines=20
  [[ "${mode}" == "full" ]] && jlines=60
  echo "## journal (últimas ${jlines} líneas)"
  if [[ -f "${P}/organic/journal.md" ]]; then
    tail -n "${jlines}" "${P}/organic/journal.md"
  else
    echo "(sin journal)"
  fi
  echo

  echo "## world (cabecera + últimas 6 del log)"
  if [[ -f "${P}/world.md" ]]; then
    awk '/^## Log reciente/{exit} {print}' "${P}/world.md" | head -n 25
    echo "--- log tail ---"
    rg '^\- \[' "${P}/world.md" | tail -n 6 || true
  fi
  echo

  echo "## policy (P0 — índice compacto)"
  if [[ -f "${P}/policy.md" ]]; then
    rg -n '^### P0\.|^## P0' "${P}/policy.md" | cut -c1-110 | head -30 || true
  fi
  echo

  echo "## working (active / cooling del mes; títulos)"
  if [[ -f "${P}/organic/working.md" ]]; then
    ym="$(date '+%Y-%m')"
    awk -v ym="${ym}" '
      /^### / { title=$0; next }
      /\*\*Estado:\*\* (active|cooling)([ (]|$)/ {
        if ($0 ~ ym && n < 4) { print title " — " $0; n++ }
      }
    ' "${P}/organic/working.md"
  fi
  echo

  echo "## incubating (open / cooking; títulos)"
  if [[ -f "${P}/incubating.md" ]]; then
    awk '
      /^## INC-/ { title=$0; next }
      /\*\*estado:\*\* (open|cooking)/ { print substr(title, 1, 110) }
    ' "${P}/incubating.md"
  fi
)"

bytes=${#out}
lines=$(printf '%s\n' "${out}" | wc -l)
printf '%s\n\n' "${out}"
if (( bytes > 12288 )); then
  echo "## fin pack — WARN_OVER_BUDGET (${bytes} bytes, ${lines} líneas)"
else
  echo "## fin pack — OK (${bytes} bytes, ${lines} líneas)"
fi