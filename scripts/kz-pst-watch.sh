#!/usr/bin/env bash
# Vigila la copia PST de esta noche. No toca el scp vivo.
# Si se cae antes de completar, relanza con rsync --inplace --partial.
# Uso: kz-pst-watch.sh <pid-scp>
set -euo pipefail

export DISPLAY="${DISPLAY:-:0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
SRC="/run/media/lalo/Backups/HM/2026/respHechoenMexico_27032026.pst"
HOST="dev.alvaro@10.100.30.109"
PORT="55014"
DST="/var/data/pst/respHechoenMexico.pst"
SSH=(ssh -o BatchMode=yes -o ConnectTimeout=15 -p "$PORT")
LOG="${KZ_HOME}/presence/pst-transfer-watch.log"
STREAM="${KZ_HOME}/presence/stream.log"
PIDFILE="${KZ_HOME}/presence/pst-watch.pid"
SCP_PID="${1:-}"

log() {
  local line
  line="$(date -Iseconds) $*"
  printf '%s\n' "$line" | tee -a "$LOG" >>"$STREAM"
}

nudge() {
  if [[ -x "${KZ_HOME}/scripts/kz-nudge.sh" ]]; then
    KZ_NUDGE_NO_CHAT_OWED=0 "${KZ_HOME}/scripts/kz-nudge.sh" --say "$*" >/dev/null 2>&1 || true
  fi
}

remote_size() {
  "${SSH[@]}" "$HOST" "stat -c %s '$DST' 2>/dev/null || echo 0"
}

remote_avail() {
  "${SSH[@]}" "$HOST" "df -B1 --output=avail /var | tail -1"
}

scp_alive() {
  local pid="$1"
  [[ -n "$pid" && -d "/proc/$pid" ]] || return 1
  tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null | grep -q 'respHechoenMexico_27032026.pst'
}

other_copy_alive() {
  local c cmd
  for c in /proc/[0-9]*/cmdline; do
    cmd="$(tr '\0' ' ' <"$c" 2>/dev/null || true)"
    case "$cmd" in
      *kz-pst-watch.sh*) continue ;;
    esac
    case "$cmd" in
      *'scp'*'respHechoenMexico_27032026.pst'*|*'rsync'*'respHechoenMexico'*)
        return 0
        ;;
    esac
  done
  return 1
}

mkdir -p "${KZ_HOME}/presence"
if [[ -z "$SCP_PID" ]]; then
  echo "uso: $0 <pid-scp>" >&2
  exit 1
fi
if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "ya hay vigilante pid=$(cat "$PIDFILE")" >&2
  exit 0
fi
echo $$ >"$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

if [[ ! -f "$SRC" ]]; then
  log "CHANGED: pst-transfer: FALLO origen no montado"
  nudge "PST: se desmontó el origen. No relanzo."
  exit 1
fi
EXPECTED="$(stat -c %s "$SRC")"

log "CHANGED: pst-transfer: vigilante ON pid=$$ scp=$SCP_PID esperado=$EXPECTED"

while scp_alive "$SCP_PID"; do
  rs="$(remote_size 2>/dev/null || echo '?')"
  log "pst-transfer: scp vivo remoto=$rs / $EXPECTED"
  sleep 60
done

log "pst-transfer: scp $SCP_PID ya no está"
sleep 3

if other_copy_alive; then
  log "CHANGED: pst-transfer: hay otra copia viva; no relanzo"
  exit 0
fi

if [[ ! -f "$SRC" ]]; then
  log "CHANGED: pst-transfer: FALLO origen desapareció al caer el scp"
  nudge "PST: se cayó el scp y el disco de origen no está. No relanzo."
  exit 1
fi

REMOTE="$(remote_size)"
AVAIL="$(remote_avail)"
NEED=$((EXPECTED - REMOTE))
log "pst-transfer: post-scp remoto=$REMOTE esperado=$EXPECTED falta=$NEED avail=$AVAIL"

if [[ "$REMOTE" -ge "$EXPECTED" ]]; then
  log "CHANGED: pst-transfer: OK scp completo $REMOTE"
  nudge "PST llegó completo por scp. Ya no hay que relanzar."
  exit 0
fi

MARGIN=2147483648
if [[ "$AVAIL" -lt $((NEED + MARGIN)) ]]; then
  log "CHANGED: pst-transfer: FALLO disco corto avail=$AVAIL need=$NEED"
  nudge "PST: se cayó el scp y en QA no cabe el resto. No relancé."
  exit 1
fi

log "CHANGED: pst-transfer: relanzo rsync --inplace --partial"
nudge "El scp del PST se cayó. Relancé rsync para continuar, no desde cero."

RLOG="${KZ_HOME}/presence/pst-rsync.log"
set +e
rsync -a --inplace --partial --info=progress2 \
  -e "ssh -p ${PORT} -o BatchMode=yes -o ConnectTimeout=15" \
  "$SRC" "${HOST}:${DST}" >>"$RLOG" 2>&1
rc=$?
set -e

REMOTE2="$(remote_size)"
if [[ "$rc" -eq 0 && "$REMOTE2" -ge "$EXPECTED" ]]; then
  log "CHANGED: pst-transfer: OK rsync completo $REMOTE2"
  nudge "PST completo por rsync. Transferencia terminada."
  exit 0
fi

log "CHANGED: pst-transfer: FALLO rsync rc=$rc remoto=$REMOTE2 / $EXPECTED"
nudge "PST: rsync también falló. Hay que verlo."
exit 1
