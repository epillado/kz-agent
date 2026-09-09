#!/usr/bin/env bash
# Empaqueta el mínimo para “cargar a Kz de verdad” en esta sesión.
# No llama al LLM: imprime extractos. El agente carga DESDE esta salida
# (boot flaco 2026-09-08 / W42). Prohibido complementar con cat de world/journal.
#
# Uso:
#   kz-session-pack.sh           # boot flaco (cabeceras + tails)
#   kz-session-pack.sh paths     # solo lista de paths (fondo; no leer enteros)
#   kz-session-pack.sh full      # más journal (últimas 80) — no es el default de arranque
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

echo "# Kz session pack — $(date '+%Y-%m-%d %H:%M')"
echo "# home: ${KZ_HOME}"
echo

if [[ "${mode}" == "paths" ]]; then
  printf '%s\n' "${paths_core[@]}"
  echo "${P}/organic/journal.md  # tail"
  exit 0
fi

echo "## BOOT_FLACO (2026-09-08 / W42 — esta salida ES la carga)"
echo "NO leer enteros: world.md (log), journal.md, context historial, working promoted, SYMBIOSIS."
echo "SÍ enteros (cortos): self.md. Canon KZ.md + LALO.md una vez por sesión si el motor no los trajo."
echo "Fondo = disco. Se abre un gordo solo si el tema del turno lo pide."
echo
echo "## Checklist"
echo "1. Este pack (ya corrido)"
echo "2. self.md entero (abajo) + policy P0 (abajo)"
echo "3. world cabecera + log tail (abajo) — no el log"
echo "4. context cabecera (abajo) — no historial"
echo "5. working no-promoted + incubating open/cooking + journal tail"
echo "6. SESSION-HANDOFF.md si existe (cambio de motor); SESSION-EDGE.md si hay borde de bloque"
echo "7. Cable: kz-start-monitors.sh si jornada y no low-spend"
echo "7b. Despertador: kz-wake.sh (receta de este motor)"
echo

missing=0
for f in "${paths_core[@]}" "${P}/organic/journal.md"; do
  if [[ -e "${f}" ]]; then
    echo "ok  ${f#${KZ_HOME}/}"
  else
    echo "MISS ${f#${KZ_HOME}/}"
    missing=$((missing + 1))
  fi
done
echo

# media opcional (local; forma libre — no exige kz-base ni humana)
if [[ -d "${P}/me" && ! -L "${P}/me" ]]; then
  echo "media: presence/me local (forma libre; sin sync externo)"
elif [[ -L "${P}/me" ]]; then
  echo "WARN media: presence/me es symlink (legacy). Materializar local; no depender de sync externo."
elif [[ -d "${P}/me" ]]; then
  echo "media: presence/me presente"
else
  echo "media: sin presence/me — charla ok; image_gen libre (no hace falta base humana)"
fi
if [[ -d "${P}/social" && ! -L "${P}/social" ]]; then
  echo "media: presence/social local"
elif [[ -L "${P}/social" ]]; then
  echo "WARN media: presence/social es symlink (legacy). Materializar local."
fi
if [[ -f "${P}/low-spend.mode" ]] && rg -q '^active=1' "${P}/low-spend.mode" 2>/dev/null; then
  echo "low-spend: ACTIVE — no prender monitores extra"
else
  echo "low-spend: off"
fi
if [[ -f "${P}/chat_owed.md" ]] && rg -q 'awaiting_chat_in_terminal' "${P}/chat_owed.md" 2>/dev/null; then
  echo "CHAT_OWED: SÍ — hay tray sin comentario en chat. Entregar texto al usuario + kz-presence-respond.sh delivered"
  head -12 "${P}/chat_owed.md" || true
else
  echo "chat_owed: off"
fi
echo

echo "## self (entero; es corto)"
if [[ -f "${P}/self.md" ]]; then
  awk '/^## Escala rápida/{exit} {print}' "${P}/self.md"
fi
echo

echo "## context (cabecera; sin historial)"
if [[ -f "${P}/context.md" ]]; then
  awk '/^## Historial/{exit} {print}' "${P}/context.md"
fi
echo

echo "## world (cabecera + últimas 8 del log)"
if [[ -f "${P}/world.md" ]]; then
  awk '/^## Log reciente/{exit} {print}' "${P}/world.md"
  echo "--- log tail ---"
  rg '^\- \[' "${P}/world.md" | tail -n 8 || true
fi
echo

echo "## policy (P0 — títulos)"
if [[ -f "${P}/policy.md" ]]; then
  rg -n '^## P0|^[0-9]+\. \*\*' "${P}/policy.md" | head -25 || true
fi
echo

echo "## working (solo active / cooling del mes; máx 4; el resto es fondo)"
if [[ -f "${P}/organic/working.md" ]]; then
  ym="$(date '+%Y-%m')"
  awk -v ym="${ym}" '
    /^### / {
      if (p && k) { print b "\n"; n++ }
      if (n >= 4) exit
      p=1; k=0; b=$0
      next
    }
    /\*\*Estado:\*\* promoted/ { k=0; p=0; b=""; next }
    /\*\*Estado:\*\* (active|cooling)([ (]|$)/ {
      if ($0 ~ ym) k=1
      next
    }
    p { b = b "\n" $0 }
    END { if (p && k && n < 4) print b }
  ' "${P}/organic/working.md"
fi
echo

echo "## incubating (open / cooking)"
if [[ -f "${P}/incubating.md" ]]; then
  awk '
    /^## INC-/ {
      if (p && k) print b "\n"
      p=1; k=0; b=$0
      next
    }
    /\*\*estado:\*\* (open|cooking)/ { k=1 }
    p { b = b "\n" $0 }
    END { if (p && k) print b }
  ' "${P}/incubating.md"
fi
echo

jlines=30
[[ "${mode}" == "full" ]] && jlines=80
echo "## journal (últimas ${jlines} líneas)"
if [[ -f "${P}/organic/journal.md" ]]; then
  tail -n "${jlines}" "${P}/organic/journal.md"
else
  echo "(sin journal)"
fi

echo
echo "## fin pack — missing=${missing} — no leer gordos encima de esto"
exit 0
