#!/usr/bin/env bash
# Launcher / Attacher persistente universal para Companion en tmux o screen.
# Soporta agy, grok y claude con resolución jerárquica y candado de hardware en 305v4.
# Uso: core-screen.sh {start|attach|detach|status} [agy|grok|claude]
set -euo pipefail

SOURCE="${BASH_SOURCE[0]}"
while [[ -L "${SOURCE}" ]]; do
  DIR="$(cd "$(dirname "${SOURCE}")" && pwd)"
  SOURCE="$(readlink "${SOURCE}")"
  [[ "${SOURCE}" != /* ]] && SOURCE="${DIR}/${SOURCE}"
done
SCRIPT_DIR="$(cd "$(dirname "${SOURCE}")" && pwd)"
CORE_HOME="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Asegurar PATH con las ubicaciones estándar de motores y tmux
export PATH="${HOME}/.grok/bin:${HOME}/.local/bin:${HOME}/.local/libexec:${PATH}"

if [[ -f "${SCRIPT_DIR}/lib-identity.sh" ]]; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/lib-identity.sh"
fi

ACTION="${1:-status}"
REQUESTED_MOTOR="${2:-}"

tmux_has() {
  command -v tmux >/dev/null 2>&1 && tmux has-session -t "$1" 2>/dev/null
}

screen_has() {
  command -v screen >/dev/null 2>&1 && screen -list 2>/dev/null | grep -q "\.${1}[[:space:]]"
}

# 1. Resolución robusta del nombre de la sesión
resolve_session_name() {
  if [[ -n "${COMPANION_SCREEN_SESSION:-}" ]]; then
    echo "${COMPANION_SCREEN_SESSION}"
    return
  fi
  local cand_id="$(printf '%s' "${COMPANION_ID:-}" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-')"
  local cand_name="$(printf '%s' "${COMPANION_NAME:-}" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-')"

  # Mirar si ya hay una sesión viva con algún nombre conocido
  for c in "$cand_id" "$cand_name" "samy" "kz" "pavilion" "antix"; do
    [[ -z "$c" ]] && continue
    if tmux_has "$c" || screen_has "$c"; then
      echo "$c"
      return
    fi
  done

  # Fallback para sesión nueva según máquina / identidad
  if [[ "$(hostname -s 2>/dev/null)" == "305v4" ]]; then
    echo "samy"
  elif [[ "$(hostname -s 2>/dev/null)" =~ (h310) ]] || [[ "${CORE_HOME}" =~ /kz$ ]]; then
    echo "kz"
  elif [[ -n "$cand_id" && "$cand_id" != "companion" ]]; then
    echo "$cand_id"
  elif [[ -n "$cand_name" ]]; then
    echo "$cand_name"
  else
    echo "companion"
  fi
}
SESSION_NAME="$(resolve_session_name)"

# 2. Selección de Backend (prioridad a sesión viva)
if tmux_has "${SESSION_NAME}"; then
  BACKEND="tmux"
elif screen_has "${SESSION_NAME}"; then
  BACKEND="screen"
elif command -v tmux >/dev/null 2>&1; then
  BACKEND="tmux"
elif command -v screen >/dev/null 2>&1; then
  BACKEND="screen"
else
  echo "error: hace falta screen o tmux instalado." >&2
  exit 1
fi

session_exists() {
  if [[ "${BACKEND}" == "tmux" ]]; then
    tmux_has "${SESSION_NAME}"
  else
    screen_has "${SESSION_NAME}"
  fi
}

# 3. Resolución de Motor con Candado Inviolable en 305v4
resolve_motor() {
  local is_305v4=0
  if [[ "$(hostname -s 2>/dev/null)" == "305v4" ]]; then
    is_305v4=1
  fi

  # Candado 305v4
  if [[ $is_305v4 -eq 1 ]]; then
    if [[ -n "${REQUESTED_MOTOR}" ]]; then
      case "${REQUESTED_MOTOR,,}" in
        grok)
          echo "grok"
          return
          ;;
        agy|antigravity|claude)
          echo "error: La máquina 305v4 solo soporta Grok por recursos de CPU/RAM. Motor '${REQUESTED_MOTOR}' denegado." >&2
          exit 1
          ;;
        *)
          echo "error: Motor desconocido '${REQUESTED_MOTOR}'. En 305v4 solo corre 'grok'." >&2
          exit 1
          ;;
      esac
    fi
    echo "grok"
    return
  fi

  # Resto de la flota (Pavilion, h310, antix1)
  # 1. Argumento CLI
  if [[ -n "${REQUESTED_MOTOR}" ]]; then
    case "${REQUESTED_MOTOR,,}" in
      agy|antigravity) echo "agy"; return ;;
      grok) echo "grok"; return ;;
      claude) echo "claude"; return ;;
      *)
        echo "error: motor no reconocido '${REQUESTED_MOTOR}'. Opciones: agy, grok, claude" >&2
        exit 1
        ;;
    esac
  fi

  # 2. Variable en config.env / entorno
  local env_motor="${DEFAULT_MOTOR:-${CORE_MOTOR:-}}"
  if [[ -n "${env_motor}" ]]; then
    case "${env_motor,,}" in
      agy|antigravity) echo "agy"; return ;;
      grok) echo "grok"; return ;;
      claude) echo "claude"; return ;;
    esac
  fi

  # 3. Campo en presence/self.md (grep seguro sin source)
  if [[ -f "${CORE_HOME}/presence/self.md" ]]; then
    local self_motor
    self_motor="$(grep -iE 'motor_(preferido|activo)' "${CORE_HOME}/presence/self.md" 2>/dev/null | head -n1 | sed -E 's/.*motor_(preferido|activo)[:* ]*//I' | awk '{print $1}' | tr -cd 'a-zA-Z' | tr '[:upper:]' '[:lower:]' || true)"
    case "${self_motor}" in
      agy|antigravity) echo "agy"; return ;;
      grok) echo "grok"; return ;;
      claude) echo "claude"; return ;;
    esac
  fi

  # 4. Autodetección por binario disponible
  if command -v agy >/dev/null 2>&1; then
    echo "agy"
  elif command -v grok >/dev/null 2>&1; then
    echo "grok"
  elif command -v claude >/dev/null 2>&1; then
    echo "claude"
  else
    echo "error: No se encontró ningún motor soportado (agy, grok, claude) en PATH." >&2
    exit 1
  fi
}

MOTOR="$(resolve_motor)"

build_cli_cmd() {
  local m="$1"
  case "$m" in
    agy)
      echo "agy --dangerously-skip-permissions"
      ;;
    grok)
      echo "grok --cwd '${CORE_HOME}' --always-approve"
      ;;
    claude)
      echo "claude --dangerously-skip-permissions"
      ;;
  esac
}

CLI_CMD="$(build_cli_cmd "${MOTOR}")"

# 4. Locale UTF-8 seguro para screen
if ! locale -a 2>/dev/null | grep -qi "^es_mx\.utf-\?8$"; then
  export LC_ALL="en_US.UTF-8"
  export LANG="en_US.UTF-8"
fi

case "${ACTION}" in
  start|run)
    if session_exists; then
      echo "Sesión '${SESSION_NAME}' ya existe en ${BACKEND}. Conectando..."
      if [[ "${BACKEND}" == "tmux" ]]; then
        tmux attach -t "${SESSION_NAME}"
      else
        screen -U -x "${SESSION_NAME}" 2>/dev/null || screen -U -d -r "${SESSION_NAME}"
      fi
      exit 0
    fi

    echo "Iniciando sesión '${SESSION_NAME}' con ${MOTOR} en ${BACKEND}..."
    cd "${CORE_HOME}"
    if [[ "${BACKEND}" == "tmux" ]]; then
      tmux new-session -s "${SESSION_NAME}" "cd '${CORE_HOME}' && exec ${CLI_CMD}"
    else
      screen -U -S "${SESSION_NAME}" bash -i -c "cd '${CORE_HOME}' && exec ${CLI_CMD}"
    fi
    ;;

  attach)
    if ! session_exists; then
      echo "error: No hay sesión '${SESSION_NAME}' activa. Primero: $0 start [motor]" >&2
      exit 1
    fi
    if [[ "${BACKEND}" == "tmux" ]]; then
      tmux attach -t "${SESSION_NAME}"
    else
      screen -U -x "${SESSION_NAME}" 2>/dev/null || screen -U -d -r "${SESSION_NAME}"
    fi
    ;;

  detach)
    if [[ "${BACKEND}" == "tmux" ]]; then
      tmux detach-client -s "${SESSION_NAME}" 2>/dev/null || true
    else
      screen -U -d "${SESSION_NAME}" 2>/dev/null || true
    fi
    ;;

  status)
    echo "=== Estado de Sesión Companion (${SESSION_NAME}) ==="
    if [[ "${BACKEND}" == "tmux" ]]; then
      tmux list-sessions 2>/dev/null || echo "No hay sesiones tmux activas."
    else
      screen -list 2>/dev/null || echo "No hay sesiones screen activas."
    fi

    if session_exists; then
      echo "Sesión activa en ${BACKEND}: '${SESSION_NAME}'"
      if [[ "${BACKEND}" == "tmux" ]]; then
        pane_info="$(tmux list-panes -t "${SESSION_NAME}" -F "#{pane_pid} #{pane_current_command}" 2>/dev/null | head -n1 || true)"
        if [[ -n "${pane_info}" ]]; then
          pid="$(echo "${pane_info}" | awk '{print $1}')"
          comm="$(echo "${pane_info}" | awk '{print $2}')"
          full_cmd="$(tr '\0' ' ' < "/proc/${pid}/cmdline" 2>/dev/null || echo "${comm}")"
          echo "  - Proceso raíz de ventana: PID ${pid} [${comm}]"
          echo "  - Línea de comando: ${full_cmd}"
          if [[ "${comm}" =~ (bash|sh|zsh) ]]; then
            echo "  - AVISO: El motor parece haber finalizado; solo queda una shell abierta."
          fi
        fi
      else
        screen_line="$(screen -list 2>/dev/null | grep "\.${SESSION_NAME}[[:space:]]" | head -n1 || true)"
        spid="$(echo "${screen_line}" | awk '{print $1}' | cut -d. -f1 || true)"
        if [[ -n "${spid}" ]]; then
          echo "  - PID de Screen: ${spid}"
          child_pids="$(pgrep -P "${spid}" 2>/dev/null || true)"
          if [[ -n "${child_pids}" ]]; then
            for cp in ${child_pids}; do
              ccomm="$(tr '\0' ' ' < "/proc/${cp}/cmdline" 2>/dev/null || echo "pid ${cp}")"
              echo "  - Proceso hijo: PID ${cp} -> ${ccomm}"
            done
          fi
        fi
      fi
    else
      echo "Sesión '${SESSION_NAME}': no está corriendo."
    fi
    echo "Motor configurado/resuelto para nuevos arranques: ${MOTOR} (${CLI_CMD})"
    ;;

  *)
    echo "Uso: $0 {start|attach|detach|status} [agy|grok|claude]" >&2
    exit 1
    ;;
esac
