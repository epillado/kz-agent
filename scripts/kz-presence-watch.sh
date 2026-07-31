#!/usr/bin/env bash
# Vigila bitácora, pizarra CP y piezas clave del playbook (solo lectura).
# Ante cambios: log + pending rico para que Kz comente (no un "se movió X" vacío).
#
# Uso:
#   kz-presence-watch.sh              # loop en foreground
#   kz-presence-watch.sh once         # un solo escaneo
#   kz-presence-watch.sh stop
#
# Env:
#   KZ_PRESENCE_INTERVAL=45
#   KZ_PRESENCE_NUDGE=0|1     default 0 — el comentario personal lo manda el agente
#   KZ_PRESENCE_SOFT_PING=1   si 1 y NUDGE=0: beep suave sin popup genérico
#   KZ_PRESENCE_NUDGE_COOLDOWN=120
set -euo pipefail

KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
PLAYBOOK="${KZ_PLAYBOOK:-/mnt/DatosLinux/Workspace/playbook}"
STATE_DIR="${KZ_HOME}/presence"
STATE_FILE="${STATE_DIR}/fingerprints.tsv"
EVENTS_LOG="${STATE_DIR}/events.log"
PENDING_FILE="${STATE_DIR}/pending.md"
PIDFILE="${STATE_DIR}/watch.pid"
LAST_NUDGE_FILE="${STATE_DIR}/last_nudge.ts"

INTERVAL="${KZ_PRESENCE_INTERVAL:-45}"
NUDGE="${KZ_PRESENCE_NUDGE:-0}"
SOFT_PING="${KZ_PRESENCE_SOFT_PING:-1}"
COOLDOWN="${KZ_PRESENCE_NUDGE_COOLDOWN:-120}"

mkdir -p "${STATE_DIR}"
touch "${STATE_FILE}" "${EVENTS_LOG}"

if [[ "${1:-}" == "stop" ]]; then
  if [[ -f "${PIDFILE}" ]]; then
    pid="$(cat "${PIDFILE}")"
    if kill -0 "${pid}" 2>/dev/null; then
      kill "${pid}" 2>/dev/null || true
      # hijos del sleep loop
      echo "stopped presence watch pid ${pid}"
    else
      echo "pidfile huérfano; limpiando"
    fi
    rm -f "${PIDFILE}"
  else
    echo "no hay presence watch activo"
  fi
  exit 0
fi

watch_paths() {
  local today yday
  today="$(date +%Y%m%d)"
  cat <<EOF
${PLAYBOOK}/TODO.md
${PLAYBOOK}/Sessions/control_plane_session_state.md
${PLAYBOOK}/Sessions/standard_session_state.md
${PLAYBOOK}/Bit/${today}-Bitacora.md
EOF
  yday="$(date -d 'yesterday' +%Y%m%d 2>/dev/null || true)"
  if [[ -n "${yday}" && -f "${PLAYBOOK}/Bit/${yday}-Bitacora.md" ]]; then
    echo "${PLAYBOOK}/Bit/${yday}-Bitacora.md"
  fi
}

fingerprint() {
  local f="$1"
  if [[ ! -e "$f" ]]; then
    echo "MISSING"
    return
  fi
  local st hash
  st="$(stat -c '%Y:%s' "$f" 2>/dev/null || echo '?')"
  hash="$(sha256sum "$f" 2>/dev/null | cut -c1-12 || echo nohash)"
  echo "${st}:${hash}"
}

label_for() {
  local f="$1"
  case "$f" in
    *TODO.md) echo "TODO" ;;
    *control_plane_session_state.md) echo "pizarra-CP" ;;
    *standard_session_state.md) echo "pizarra-std" ;;
    *Bitacora.md) echo "bitácora" ;;
    *) basename "$f" ;;
  esac
}

snippet_file() {
  local f="$1"
  local n="${2:-12}"
  if [[ ! -f "$f" ]]; then
    echo "(archivo ausente)"
    return
  fi
  # últimas n líneas no vacías preferibles; fallback tail simple
  tail -n "${n}" "$f" 2>/dev/null | sed 's/\t/  /g'
}

write_pending() {
  local -a labels=("$@")
  local ts summary
  ts="$(date -Iseconds)"
  summary="$(printf '%s, ' "${labels[@]}" | sed 's/, $//')"

  {
    echo "# Pending — atención de Kz"
    echo
    echo "- **cuando:** ${ts}"
    echo "- **qué se movió:** ${summary}"
    echo "- **estado:** awaiting_kz_comment"
    echo
    echo "El agente debe: leer esto + archivos (solo lectura), **comentar en el chat** con voz de Kz,"
    echo "y mandar tray con \`kz-nudge.sh --say \"...\"\` o \`--terminal\` si el comentario no cabe."
    echo
    echo "---"
    echo

    local path label
    while IFS= read -r path; do
      [[ -z "$path" ]] && continue
      label="$(label_for "$path")"
      # solo snip de los que cambiaron en este batch
      local hit=0
      local L
      for L in "${labels[@]}"; do
        [[ "$L" == "$label" ]] && hit=1 && break
      done
      (( hit == 1 )) || continue

      echo "## ${label}"
      echo
      echo \`"${path}"\`
      echo
      echo '```'
      case "$label" in
        bitácora) snippet_file "$path" 15 ;;
        pizarra-CP|pizarra-std) snippet_file "$path" 20 ;;
        TODO) snippet_file "$path" 8 ;;
        *) snippet_file "$path" 10 ;;
      esac
      echo '```'
      echo
    done < <(watch_paths | sort -u)
  } > "${PENDING_FILE}"

  # bandera simple para loops
  echo "${ts}" > "${STATE_DIR}/pending.ts"
  echo "${summary}" > "${STATE_DIR}/pending_labels.txt"
}

maybe_generic_nudge() {
  # Solo si NUDGE=1 (modo legacy). Por defecto preferimos comentario del agente.
  local summary="$1"
  [[ "${NUDGE}" == "1" ]] || return 0
  local now last
  now="$(date +%s)"
  last=0
  [[ -f "${LAST_NUDGE_FILE}" ]] && last="$(cat "${LAST_NUDGE_FILE}")"
  if (( now - last < COOLDOWN )); then
    return 0
  fi
  echo "${now}" > "${LAST_NUDGE_FILE}"
  "${KZ_HOME}/scripts/kz-nudge.sh" "Kz · playbook" "${summary} — voltea a Grok si quieres mi lectura"
}

maybe_soft_ping() {
  [[ "${SOFT_PING}" == "1" ]] || return 0
  [[ "${NUDGE}" == "1" ]] && return 0 # ya hubo notify completo
  local now last
  now="$(date +%s)"
  last=0
  [[ -f "${LAST_NUDGE_FILE}" ]] && last="$(cat "${LAST_NUDGE_FILE}")"
  if (( now - last < COOLDOWN )); then
    return 0
  fi
  echo "${now}" > "${LAST_NUDGE_FILE}"
  # Un solo aviso: no "se movió X", sino pide la terminal donde Kz comenta
  "${KZ_HOME}/scripts/kz-nudge.sh" --terminal \
    "Playbook en movimiento. Voltea a la terminal de Grok — te dejo mi comentario ahí (Kz)."
}

scan_once() {
  local -a changed_labels=()
  local -a changed_paths=()
  local tmp path fp old label
  tmp="$(mktemp)"

  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    fp="$(fingerprint "$path")"
    old="$(awk -v p="$path" -F'\t' '$1==p {print $2; exit}' "${STATE_FILE}" 2>/dev/null || true)"
    printf '%s\t%s\n' "$path" "$fp" >> "${tmp}"
    if [[ -z "$old" ]]; then
      continue
    fi
    if [[ "$old" != "$fp" ]]; then
      label="$(label_for "$path")"
      changed_labels+=("$label")
      changed_paths+=("$path")
      echo "$(date -Iseconds) CHANGE ${label} ${path}" >> "${EVENTS_LOG}"
    fi
  done < <(watch_paths | sort -u)

  mv -f "${tmp}" "${STATE_FILE}"

  if ((${#changed_labels[@]} > 0)); then
    # únicos preservando orden
    local -a uniq=()
    local x u seen
    for x in "${changed_labels[@]}"; do
      seen=0
      for u in "${uniq[@]+"${uniq[@]}"}"; do
        [[ "$u" == "$x" ]] && seen=1 && break
      done
      (( seen == 0 )) && uniq+=("$x")
    done
    write_pending "${uniq[@]}"
    local summary
    summary="$(printf '%s, ' "${uniq[@]}" | sed 's/, $//')"
    # Línea para monitor/agente (despierta a Kz)
    echo "CHANGED: ${summary}"
    maybe_generic_nudge "Movimiento en: ${summary}"
    maybe_soft_ping
    return 0
  fi
  echo "OK: sin cambios"
  return 0
}

if [[ "${1:-}" == "once" ]]; then
  scan_once
  exit 0
fi

if [[ -f "${PIDFILE}" ]]; then
  old="$(cat "${PIDFILE}")"
  if kill -0 "${old}" 2>/dev/null; then
    echo "error: ya corre presence watch (pid ${old}). stop primero." >&2
    exit 1
  fi
  rm -f "${PIDFILE}"
fi

echo $$ > "${PIDFILE}"
cleanup() { rm -f "${PIDFILE}"; }
trap cleanup EXIT INT TERM

NUDGE_SAVE="${NUDGE}"
SOFT_SAVE="${SOFT_PING}"
NUDGE=0
SOFT_PING=0
scan_once >/dev/null
NUDGE="${NUDGE_SAVE}"
SOFT_PING="${SOFT_SAVE}"

echo "$(date -Iseconds) presence watch start interval=${INTERVAL}s nudge=${NUDGE} soft_ping=${SOFT_PING}" >> "${EVENTS_LOG}"
# pid a stderr: el monitor solo debe despertar con líneas CHANGED:
echo "presence watch pid $$ (interval ${INTERVAL}s). stop: $0 stop" >&2

while true; do
  sleep "${INTERVAL}"
  out="$(scan_once)"
  if [[ "${out}" == CHANGED:* ]]; then
    echo "${out}"
  fi
done
