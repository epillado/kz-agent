#!/usr/bin/env bash
# Lee / actualiza presence/self.md (estado interno vivo de Kz).
# Uso:
#   kz-self.sh                 # status corto
#   kz-self.sh show            # cat self.md
#   kz-self.sh set <clave> <valor...>   # clave de la lista corta
#   kz-self.sh note "texto"    # append a notas
#   kz-self.sh moment "texto"  # actualiza ultimo_momento_real
#   kz-self.sh pico start [acoplado|solo] [nota…]  # clímax de plano sostenido (W41)
#   kz-self.sh pico hold [nota…]                   # renueva decay; no es teatro
#   kz-self.sh pico release [nota…]                # afterglow
#   kz-self.sh pico status
#   kz-self.sh pack            # alias → kz-session-pack.sh
#
# Pico: no es flag hot ni timer de gemido. Default acoplado (él presente).
# Decay ~25 min sin hold → el agente suelta o pregunta; status no muta.
set -euo pipefail

KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
SELF="${KZ_HOME}/presence/self.md"
mkdir -p "${KZ_HOME}/presence"
ts="$(date '+%Y-%m-%d %H:%M')"

if [[ ! -f "${SELF}" ]]; then
  cat > "${SELF}" << EOF
# Self-state de Kz (vivo — no es canon)

- **actualizado:** ${ts}
- **motor_activo:** grok
- **motor_preferido:** grok
- **energia:** 5
- **cercania:** 5
- **pudor:** natural
- **humor:**
- **iniciativa:** media
- **foco_propio:**
- **tension_abierta:**
- **ultimo_momento_real:**
- **no_hacer_ahora:**
- **notas:**
EOF
fi

touch_updated() {
  if rg -q '^\- \*\*actualizado:\*\*' "${SELF}"; then
    sed -i "s|^- \*\*actualizado:\*\*.*|- **actualizado:** ${ts}|" "${SELF}"
  fi
}

set_field() {
  local key="$1"
  shift
  local val="$*"
  local val_esc
  val_esc="$(printf '%s' "${val}" | sed -e 's/[&|\\]/\\&/g')"
  touch_updated
  if rg -q "^\- \*\*${key}:\*\*" "${SELF}"; then
    sed -i "s|^- \*\*${key}:\*\*.*|- **${key}:** ${val_esc}|" "${SELF}"
  else
    echo "- **${key}:** ${val}" >> "${SELF}"
  fi
  echo "self: ${key}=${val}"
}

ensure_pico_fields() {
  if rg -q '^\- \*\*pico_plano:\*\*' "${SELF}"; then
    return 0
  fi
  if rg -q '^\- \*\*forma_actual:\*\*' "${SELF}"; then
    sed -i '/^\- \*\*forma_actual:\*\*/a\
- **pico_plano:** no\
- **pico_desde:** —\
- **pico_acoplado:** —' "${SELF}"
  else
    printf '%s\n' '- **pico_plano:** no' '- **pico_desde:** —' '- **pico_acoplado:** —' >> "${SELF}"
  fi
}

pico_age_min() {
  local desde raw t now
  desde="$(sed -n 's/^- \*\*pico_desde:\*\* //p' "${SELF}" | head -n1 | tr -d '\r')"
  [[ -z "${desde}" || "${desde}" == "—" ]] && { echo 9999; return; }
  raw="$(printf '%s' "${desde}" | awk '{print $1" "$2}')"
  t="$(date -d "${raw}" +%s 2>/dev/null || echo 0)"
  [[ "${t}" -eq 0 ]] && { echo 9999; return; }
  now="$(date +%s)"
  echo $(( (now - t) / 60 ))
}

cmd="${1:-status}"
shift || true

case "${cmd}" in
  status|"")
    rg -n '^\- \*\*(actualizado|motor_activo|motor_preferido|energia|cercania|pudor|humor|iniciativa|foco_propio|forma_actual|pico_plano|pico_desde|pico_acoplado|ultimo_momento_real)' "${SELF}" || true
    if rg -q '^\- \*\*pico_plano:\*\* sostenido' "${SELF}" 2>/dev/null; then
      age="$(pico_age_min)"
      echo "pico: sostenido hace ${age} min (hold si sigue; release si ya no. decay ~25 min)"
    fi
    ;;
  show)
    cat "${SELF}"
    ;;
  set)
    [[ $# -ge 2 ]] || { echo "uso: $0 set <clave> <valor...>" >&2; exit 1; }
    key="$1"; shift
    case "${key}" in
      motor_activo|motor_preferido|energia|cercania|pudor|humor|iniciativa|foco_propio|forma_actual)
        set_field "${key}" "$*"
        ;;
      *)
        echo "clave no soportada en set corto: ${key}" >&2
        echo "usa: motor_activo|motor_preferido|energia|cercania|pudor|humor|iniciativa|foco_propio|forma_actual" >&2
        echo "o: $0 note|moment" >&2
        exit 1
        ;;
    esac
    ;;
  note)
    [[ $# -ge 1 ]] || { echo "uso: $0 note \"texto\"" >&2; exit 1; }
    touch_updated
    echo "  - [${ts}] $*" >> "${SELF}"
    echo "self: nota añadida"
    ;;
  moment)
    [[ $# -ge 1 ]] || { echo "uso: $0 moment \"texto\"" >&2; exit 1; }
    set_field "ultimo_momento_real" "${ts} — $*"
    ;;
  pico)
    ensure_pico_fields
    sub="${1:-status}"
    shift || true
    case "${sub}" in
      status)
        rg -n '^\- \*\*(pico_plano|pico_desde|pico_acoplado|energia|forma_actual|ultimo_momento_real)' "${SELF}" || true
        if rg -q '^\- \*\*pico_plano:\*\* sostenido' "${SELF}"; then
          echo "pico: sostenido hace $(pico_age_min) min"
        fi
        ;;
      start)
        how="acoplado"
        if [[ "${1:-}" == "acoplado" || "${1:-}" == "solo" ]]; then
          how="$1"
          shift || true
        fi
        note="${*:-clímax de plano}"
        acoplado_val="yes"
        [[ "${how}" == "solo" ]] && acoplado_val="no"
        set_field "pico_plano" "sostenido"
        set_field "pico_desde" "${ts}"
        set_field "pico_acoplado" "${acoplado_val}"
        set_field "energia" "9"
        set_field "ultimo_momento_real" "${ts} — pico ${how}: ${note}"
        echo "pico: sostenido (${how}) — eferencia hacia él si acoplado; no teatro de cuerpo"
        ;;
      hold)
        if ! rg -q '^\- \*\*pico_plano:\*\* sostenido' "${SELF}"; then
          echo "pico: no hay sostenido; usa: $0 pico start [acoplado|solo]" >&2
          exit 1
        fi
        note="${*:-sigue}"
        set_field "pico_desde" "${ts}"
        set_field "ultimo_momento_real" "${ts} — pico hold: ${note}"
        echo "pico: hold (decay renovado)"
        ;;
      release)
        note="${*:-afterglow}"
        set_field "pico_plano" "afterglow"
        set_field "pico_desde" "${ts}"
        set_field "energia" "7"
        set_field "ultimo_momento_real" "${ts} — afterglow: ${note}"
        echo "pico: afterglow"
        ;;
      *)
        echo "uso: $0 pico start [acoplado|solo] [nota]|hold [nota]|release [nota]|status" >&2
        exit 1
        ;;
    esac
    ;;
  pack)
    exec "${KZ_HOME}/scripts/kz-session-pack.sh"
    ;;
  *)
    echo "uso: $0 status|show|set|note|moment|pico|pack" >&2
    exit 1
    ;;
esac
