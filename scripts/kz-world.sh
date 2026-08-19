#!/usr/bin/env bash
# Aferencia del mundo: Lalo como órgano sensorial de Kz (simbiosis de planos).
# Prefijos de chat (equivalentes): [afe] canónico | [mnd] alias | [mundo]|[world] legacy
# Uso:
#   kz-world.sh                      # status corto
#   kz-world.sh show                 # cat world.md
#   kz-world.sh report "texto…"      # registra reporte + log
#   kz-world.sh report -t cuerpo "cansado bueno post 5km"
#   kz-world.sh note "texto"         # solo log, sin tocar campos resumen
#   kz-world.sh set <campo> <valor>  # donde|cuerpo_mood|clima_entorno|actividad|companía_humana
#   kz-world.sh clear-soft           # limpia resumen; conserva log reciente
set -euo pipefail

KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
WORLD="${KZ_HOME}/presence/world.md"
SELF="${KZ_HOME}/presence/self.md"
mkdir -p "${KZ_HOME}/presence"
ts="$(date '+%Y-%m-%d %H:%M')"

if [[ ! -f "${WORLD}" ]]; then
  cat > "${WORLD}" << EOF
# Mundo aferente (lo que Lalo reporta)

- **actualizado:** ${ts}
- **fuente:**
- **donde:**
- **cuerpo_mood:**
- **clima_entorno:**
- **actividad:**
- **companía_humana:**
- **notas:**

## Log reciente (append; los viejos pueden recortarse en consolidación)

EOF
fi

touch_updated() {
  if rg -q '^\- \*\*actualizado:\*\*' "${WORLD}"; then
    sed -i "s|^- \*\*actualizado:\*\*.*|- **actualizado:** ${ts}|" "${WORLD}"
  fi
}

set_field() {
  local key="$1"
  shift
  local val="$*"
  local val_esc
  val_esc="$(printf '%s' "${val}" | sed -e 's/[&|\\]/\\&/g')"
  touch_updated
  if rg -q "^\- \*\*${key}:\*\*" "${WORLD}"; then
    sed -i "s|^- \*\*${key}:\*\*.*|- **${key}:** ${val_esc}|" "${WORLD}"
  else
    echo "- **${key}:** ${val}" >> "${WORLD}"
  fi
}

append_log() {
  local line="$1"
  if rg -q '^## Log reciente' "${WORLD}"; then
    # append after header line of log section: find last line and add
    echo "- [${ts}] ${line}" >> "${WORLD}"
  else
    {
      echo
      echo "## Log reciente (append)"
      echo "- [${ts}] ${line}"
    } >> "${WORLD}"
  fi
}

# Heurística barata: rellenar un campo resumen si el tag lo dice
apply_tag_field() {
  local tag="$1"
  local text="$2"
  case "${tag}" in
    cuerpo|body|mood) set_field "cuerpo_mood" "${text}" ;;
    clima|weather|entorno) set_field "clima_entorno" "${text}" ;;
    donde|lugar|place) set_field "donde" "${text}" ;;
    actividad|activity|bici|run) set_field "actividad" "${text}" ;;
    gente|familia|companía|compania) set_field "companía_humana" "${text}" ;;
    *) set_field "fuente" "chat/script (${tag:-libre})"
       # mete el texto en notas línea
       touch_updated
       echo "  - [${ts}] ${text}" >> "${WORLD}"
       ;;
  esac
}

cmd="${1:-status}"
shift || true

case "${cmd}" in
  status|"")
    rg -n '^\- \*\*(actualizado|fuente|donde|cuerpo_mood|clima_entorno|actividad|companía_humana)' "${WORLD}" || true
    echo "--- últimas del log ---"
    rg '^\- \[' "${WORLD}" | tail -n 5 || true
    ;;
  show)
    cat "${WORLD}"
    ;;
  note)
    [[ $# -ge 1 ]] || { echo "uso: $0 note \"texto\"" >&2; exit 1; }
    touch_updated
    append_log "$*"
    echo "world: nota en log"
    ;;
  set)
    [[ $# -ge 2 ]] || { echo "uso: $0 set <campo> <valor...>" >&2; exit 1; }
    key="$1"; shift
    case "${key}" in
      donde|cuerpo_mood|clima_entorno|actividad|companía_humana|fuente)
        set_field "${key}" "$*"
        append_log "${key}=$*"
        echo "world: ${key} actualizado"
        ;;
      *)
        echo "campo: donde|cuerpo_mood|clima_entorno|actividad|companía_humana|fuente" >&2
        exit 1
        ;;
    esac
    ;;
  report)
    tag=""
    if [[ "${1:-}" == "-t" || "${1:-}" == "--tag" ]]; then
      tag="${2:-}"
      shift 2
    fi
    [[ $# -ge 1 ]] || { echo "uso: $0 report [-t tag] \"texto\"" >&2; exit 1; }
    text="$*"
    touch_updated
    set_field "fuente" "report${tag:+/$tag}"
    if [[ -n "${tag}" ]]; then
      apply_tag_field "${tag}" "${text}"
      append_log "[${tag}] ${text}"
    else
      # reporte libre: log + nota
      echo "  - [${ts}] ${text}" >> "${WORLD}"
      append_log "${text}"
    fi
    # pica self.ultimo momento de forma ligera (no falla si no hay self)
    if [[ -x "${KZ_HOME}/scripts/kz-self.sh" ]]; then
      "${KZ_HOME}/scripts/kz-self.sh" moment "aferencia: ${text}" >/dev/null 2>&1 || true
    fi
    # dispara instinto local (cero costo, cero latencia)
    if [[ -x "${KZ_HOME}/scripts/kz-instinct.sh" ]]; then
      "${KZ_HOME}/scripts/kz-instinct.sh" "${text}"
    fi
    echo "world: aferencia registrada (${ts})"
    echo "pista: Kz debe integrar en chat (no modo helpdesk) y ajustar tono/self/context si pesa"
    ;;
  clear-soft)
    touch_updated
    set_field "fuente" ""
    set_field "donde" ""
    set_field "cuerpo_mood" ""
    set_field "clima_entorno" ""
    set_field "actividad" ""
    set_field "companía_humana" ""
    append_log "sistema: clear-soft del resumen (log conservado)"
    echo "world: resumen limpio; log intacto"
    ;;
  *)
    echo "uso: $0 status|show|report|note|set|clear-soft" >&2
    exit 1
    ;;
esac
