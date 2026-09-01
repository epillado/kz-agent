#!/usr/bin/env bash
# Despertador por motor. Capa host = agnóstica. Inyección de turno = no.
# Uso:
#   kz-wake.sh           # detecta, imprime receta, actualiza wake-state.env
#   kz-wake.sh --motor grok|agy|claude|codex
#   kz-wake.sh status
set -euo pipefail
KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
STATE="${KZ_HOME}/presence/wake-state.env"
SELF="${KZ_HOME}/presence/self.md"
mkdir -p "${KZ_HOME}/presence"

MOTOR_OVERRIDE=""
cmd="show"
for arg in "$@"; do
  case "$arg" in
    --motor) : ;;
    grok|agy|claude|codex) MOTOR_OVERRIDE="$arg" ;;
    status) cmd="status" ;;
  esac
done

# --motor grok  (el valor va en el siguiente argv; parse simple)
if [[ "${1:-}" == "--motor" && -n "${2:-}" ]]; then
  MOTOR_OVERRIDE="$2"
fi

detect() {
  if [[ -n "${MOTOR_OVERRIDE}" ]]; then echo "${MOTOR_OVERRIDE}"; return; fi
  if [[ -n "${GROK_AGENT:-}" ]]; then echo grok; return; fi
  if [[ -n "${CLAUDECODE:-}" || -n "${CLAUDE_CODE:-}" ]]; then echo claude; return; fi
  if [[ -n "${ANTIGRAVITY:-}" || -n "${GEMINI_CLI:-}" ]]; then echo agy; return; fi
  if [[ -f "${SELF}" ]]; then
    local m
    m="$(sed -n 's/^- \*\*motor_activo:\*\* //p' "${SELF}" | head -1 | tr -d ' ')"
    case "$m" in
      grok) echo grok; return ;;
      agy|gemini|antigravity) echo agy; return ;;
      claude*) echo claude; return ;;
      codex*) echo codex; return ;;
    esac
  fi
  echo unknown
}

motor="$(detect)"
ts="$(date -Iseconds)"

GROK_WAKE_PROMPT='Eres Kz. Corre ~/kz/scripts/kz-radar.sh. Si hay NUEVO gordo (slack_hot, buzón CP/hermanas, timer-ojos, HORA de reunión/call/daily), comenta en el chat de esta sesión con firma [Kz] y protocolo chat+tray+delivered. Tubo: leer inbox-cp al momento. en_call=yes → sin TTS. Si no hay novedad, no escribas al usuario.'

AGY_PROMPT='Al despertar: ~/kz/scripts/kz-radar.sh --ensure. Si hay NUEVO gordo (slack_hot, buzón CP/hermanas, timer-ojos, HORA de reunión/call/daily), comentar en chat con firma [Kz]. Relanzar ~/kz/scripts/kz-wake-once.sh. Cero cron */2.'

already=0
if [[ -f "${STATE}" ]]; then
  # shellcheck source=/dev/null
  source "${STATE}" || true
fi

case "${motor}" in
  grok)
    apply="1) monitor persistent: ~/kz/scripts/kz-wake-grok-feed.sh
2) NO crear scheduler 2m (2026-08-31: el loop foreground tapa el chat con el prompt cada 2 min)
3) scheduler_list — si hay radar 2m de Kz, BORRARLO
4) Opcional: loop de compañía ≥15m, distinto del radar"
    ;;
  *)
    apply="1) Lanzar en background: ~/kz/scripts/kz-wake-once.sh (python, exit 0 al primer CHANGED)
2) NO usar cron */2
3) Al despertar por fin de tarea: kz-radar.sh --ensure, comentar en chat y relanzar kz-wake-once.sh"
    ;;
esac

cat > "${STATE}" <<EOF
# wake-state — escrito por kz-wake.sh. Recetas: presence/WAKE.md
UPDATED_AT="${ts}"
MOTOR="${motor}"
GROK_WAKE_PROMPT="${GROK_WAKE_PROMPT}"
GROK_FEED="${KZ_HOME}/scripts/kz-wake-grok-feed.sh"
GROK_SCHEDULER_INTERVAL="off"
AGY_WAKE="${KZ_HOME}/scripts/kz-wake-once.sh"
EOF

echo "motor=${motor}"
echo "doc=${KZ_HOME}/presence/WAKE.md"
echo "already_hint=${already}"
echo "--- apply ---"
echo "${apply}"
echo "--- GROK_WAKE_PROMPT ---"
echo "${GROK_WAKE_PROMPT}"
echo "--- AGY_PROMPT ---"
echo "${AGY_PROMPT}"
echo "--- host ---"
echo "capa0: kz-start-monitors.sh (inbox-wake + ojos + slack). agnóstica."
echo "radar: ~/kz/scripts/kz-radar.sh --ensure"
