#!/usr/bin/env bash
# Cola de incubación (MVP mente Kz).
# Uso:
#   kz-incubate.sh list
#   kz-incubate.sh add "título" "detalle opcional..."
#   kz-incubate.sh cooking INC-001
#   kz-incubate.sh delivered INC-001 "resumen de lo que salió"
#   kz-incubate.sh close INC-001
#   kz-incubate.sh drop INC-001
set -euo pipefail

KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
INC="${KZ_HOME}/presence/incubating.md"
SEQ="${KZ_HOME}/presence/incubating.seq"
mkdir -p "${KZ_HOME}/presence"
ts="$(date '+%Y-%m-%d %H:%M')"

[[ -f "${INC}" ]] || echo "# Temas en incubación" > "${INC}"
[[ -f "${SEQ}" ]] || echo "0" > "${SEQ}"

next_id() {
  local n
  n="$(cat "${SEQ}")"
  n=$((n + 1))
  echo "${n}" > "${SEQ}"
  printf 'INC-%03d' "${n}"
}

cmd="${1:-list}"
shift || true

case "${cmd}" in
  list)
    if rg -q '^## INC-' "${INC}" 2>/dev/null; then
      rg -n '^## INC-|\*\*estado:\*\*' "${INC}" || true
    else
      echo "(sin incubaciones)"
    fi
    ;;
  add)
    [[ $# -ge 1 ]] || { echo "uso: $0 add \"título\" [detalle...]" >&2; exit 1; }
    title="$1"; shift || true
    detail="${*:-}"
    id="$(next_id)"
    {
      echo
      echo "## ${id} — ${title}"
      echo "- **estado:** open"
      echo "- **desde:** ${ts}"
      echo "- **pedido por:** Lalo"
      echo "- **qué:** ${detail:-$title}"
      echo "- **no hacer aún:**"
      echo "- **señal de listo:** propuesta o siguiente paso concreto"
      echo "- **resultado:**"
    } >> "${INC}"
    echo "incubating: added ${id} — ${title}"
    # soft context note
    if [[ -x "${KZ_HOME}/scripts/kz-context.sh" ]]; then
      "${KZ_HOME}/scripts/kz-context.sh" note "incubación ${id}: ${title}" 2>/dev/null || true
    fi
    ;;
  cooking|delivered|close|drop)
    [[ $# -ge 1 ]] || { echo "uso: $0 ${cmd} INC-XXX [nota]" >&2; exit 1; }
    id="$1"; shift || true
    note="${*:-}"
    case "${cmd}" in
      cooking) st=cooking ;;
      delivered) st=delivered ;;
      close) st=closed ;;
      drop) st=dropped ;;
    esac
    # update estado under the matching ## header (first **estado** after header)
    if ! rg -q "^## ${id} " "${INC}"; then
      echo "error: no está ${id}" >&2
      exit 1
    fi
    # awk: when in section, replace estado line once
    awk -v id="${id}" -v st="${st}" -v note="${note}" -v ts="${ts}" '
      BEGIN { insec=0; done=0 }
      $0 ~ "^## " id " " { insec=1; print; next }
      /^## / { insec=0 }
      insec && !done && /^\- \*\*estado:\*\*/ {
        print "- **estado:** " st
        done=1
        next
      }
      insec && note != "" && /^\- \*\*resultado:\*\*/ && st == "delivered" {
        print "- **resultado:** [" ts "] " note
        next
      }
      { print }
    ' "${INC}" > "${INC}.tmp" && mv "${INC}.tmp" "${INC}"
    if [[ "${st}" == "delivered" && -n "${note}" ]]; then
      # append delivery stamp if resultado was empty pattern only
      :
    fi
    echo "incubating: ${id} → ${st}"
    if [[ "${st}" == "delivered" ]]; then
      "${KZ_HOME}/scripts/kz-nudge.sh" --say "Incubación ${id}: ya tengo algo. Voltea a Grok." 2>/dev/null || true
    fi
    ;;
  *)
    echo "uso: $0 list|add|cooking|delivered|close|drop" >&2
    exit 1
    ;;
esac
