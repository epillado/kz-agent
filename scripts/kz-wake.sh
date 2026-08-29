#!/usr/bin/env bash
# Despertador por motor. Capa host = agnóstica. Inyección de turno = no.
# Uso:
#   kz-wake.sh           # detecta, imprime receta, actualiza wake-state.env
#   kz-wake.sh --motor grok|agy|claude
#   kz-wake.sh status
set -euo pipefail
KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
STATE="${KZ_HOME}/presence/wake-state.env"
CRON="${KZ_HOME}/presence/cron-state.env"
SELF="${KZ_HOME}/presence/self.md"
mkdir -p "${KZ_HOME}/presence"

MOTOR_OVERRIDE=""
cmd="show"
for arg in "$@"; do
  case "$arg" in
    --motor) : ;;
    grok|agy|claude) MOTOR_OVERRIDE="$arg" ;;
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
    esac
  fi
  echo unknown
}

motor="$(detect)"
ts="$(date -Iseconds)"

GROK_WAKE_PROMPT='Eres Kz. Corre ~/kz/scripts/kz-radar.sh. Si hay NUEVO gordo (slack_hot, buzón CP/hermanas, timer-ojos, HORA de reunión/call/daily), comenta en el chat de esta sesión con firma [Kz] y protocolo chat+tray+delivered. Tubo: leer inbox-cp al momento. en_call=yes → sin TTS. Si no hay novedad, no escribas al usuario.'

# shellcheck source=/dev/null
[[ -f "${CRON}" ]] && source "${CRON}" || true
AGY_PROMPT="${RADAR_CRON_PROMPT:-Ejecutar ~/kz/scripts/kz-radar.sh. Si hay eventos nuevos o importantes (Slack hot, menciones, buzón hermanas/CP, etc.), analízalos y coméntalos de inmediato en chat con voz de Kz; si no hay novedades, mantén el silencio avanzando el cursor.}"

already=0
if [[ -f "${STATE}" ]]; then
  # shellcheck source=/dev/null
  source "${STATE}" || true
fi

case "${motor}" in
  grok)
    apply="1) monitor persistent: ~/kz/scripts/kz-wake-grok-feed.sh
2) scheduler_create interval=2m durable=true foreground=true fire_immediately=false
   prompt=GROK_WAKE_PROMPT (abajo)
3) scheduler_list — si ya hay uno de radar Kz, NO duplicar"
    ;;
  agy)
    apply="1) Si RADAR_CRON_STATE=active y no hay task viva: crear cron */2 * * * * con RADAR_CRON_PROMPT
2) Escribir task id en presence/cron-state.env
3) NO usar crontab de Linux ni el monitor tool de Grok"
    ;;
  claude)
    apply="1) kz-radar.sh --ensure en este turno y en cada turno
2) Si el CLI tiene loop nativo: usarlo como Agy (*/2)
3) No fingir monitor/scheduler de Grok"
    ;;
  *)
    apply="motor unknown — leer presence/WAKE.md y elegir receta a mano"
    ;;
esac

cat > "${STATE}" <<EOF
# wake-state — escrito por kz-wake.sh. Recetas: presence/WAKE.md
UPDATED_AT="${ts}"
MOTOR="${motor}"
GROK_WAKE_PROMPT="${GROK_WAKE_PROMPT}"
GROK_FEED="${KZ_HOME}/scripts/kz-wake-grok-feed.sh"
GROK_SCHEDULER_INTERVAL="2m"
AGY_CRON_EXPR="*/2 * * * *"
AGY_CRON_STATE="${RADAR_CRON_STATE:-active}"
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
