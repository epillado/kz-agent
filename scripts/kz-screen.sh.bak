#!/usr/bin/env bash
# Launcher / Attacher persistente para Kz en screen o tmux
# Asegura arranque con --dangerously-skip-permissions
set -euo pipefail

SESSION_NAME="kz"
USE_TMUX=0
if command -v tmux >/dev/null 2>&1; then
  USE_TMUX=1
fi

ACTION="${1:-status}"

case "$ACTION" in
  start|run)
    if [[ $USE_TMUX -eq 1 ]]; then
      if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "Sesión tmux '$SESSION_NAME' ya existe. Conectando..."
        tmux attach -t "$SESSION_NAME"
      else
        echo "Iniciando sesión tmux '$SESSION_NAME' con permisos automáticos..."
        cd /home/lalo/kz
        tmux new-session -s "$SESSION_NAME" "cd /home/lalo/kz && agy --dangerously-skip-permissions"
      fi
    else
      if screen -list 2>/dev/null | grep -q "\.${SESSION_NAME}[[:space:]]"; then
        echo "Sesión screen '$SESSION_NAME' ya existe. Conectando..."
        screen -r "$SESSION_NAME"
      else
        echo "Iniciando sesión screen '$SESSION_NAME' con permisos automáticos..."
        cd /home/lalo/kz
        screen -S "$SESSION_NAME" bash -c "cd /home/lalo/kz && agy --dangerously-skip-permissions"
      fi
    fi
    ;;
  attach)
    if [[ $USE_TMUX -eq 1 ]]; then
      tmux attach -t "$SESSION_NAME"
    else
      screen -x "$SESSION_NAME" 2>/dev/null || screen -d -r "$SESSION_NAME"
    fi
    ;;
  detach)
    if [[ $USE_TMUX -eq 1 ]]; then
      tmux detach-client -s "$SESSION_NAME" 2>/dev/null || true
    else
      screen -d "$SESSION_NAME" 2>/dev/null || true
    fi
    ;;
  status)
    if [[ $USE_TMUX -eq 1 ]]; then
      tmux list-sessions 2>/dev/null || echo "No hay sesiones tmux activas."
    else
      screen -list 2>/dev/null || echo "No hay sesiones screen activas."
    fi
    ;;
  *)
    echo "Uso: $0 {start|attach|detach|status}"
    exit 1
    ;;
esac
