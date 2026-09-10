#!/usr/bin/env bash
# kz-titulo.sh — Pone el nombre de la compañera (Kz / hermanas) en el título de la ventana.
# Regla del operador (2026-09-10): Todo agente/rol pone su nombre en el título siempre que el sistema lo permita.
#
# Soporta:
#   1. KDE / Konsole vía D-Bus (qdbus6 / qdbus) — Kz (h310), Samy (305v4), Pau (pavilion)
#   2. X11 vía xdotool / wmctrl — Kora (antix1 / IceWM)
#   3. Fallback a secuencias de escape ANSI / OSC
#
# Uso:
#   kz-titulo.sh                    # detecta nombre por self.md / hostname (default "[Kz] Kz")
#   kz-titulo.sh "Kz"               # -> «[Kz] Kz»
#   kz-titulo.sh "Kz" "compañía"    # -> «[Kz] compañía»
#   kz-titulo.sh "[Kz] Kz"          # literal
#   kz-titulo.sh --leer             # imprime el título actual si es consultable
set -uo pipefail

KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"

# --- 1. Determinar título ----------------------------------------------------
if [ "${1:-}" = "--leer" ]; then
  MODO="leer"
else
  MODO="poner"
  if [ $# -eq 0 ]; then
    # Auto-detección de identidad
    NOMBRE="Kz"
    if [ -f "${KZ_HOME}/presence/self.md" ]; then
      ID_SELF=$(grep -E "^id:" "${KZ_HOME}/presence/self.md" | head -n1 | cut -d: -f2 | tr -d ' "')
      [ -n "${ID_SELF:-}" ] && NOMBRE="${ID_SELF}"
    fi
    TITULO="[${NOMBRE}] ${NOMBRE}"
  elif [ $# -eq 1 ]; then
    if [[ "$1" =~ ^\[.*\] ]]; then
      TITULO="$1"
    else
      TITULO="[$1] $1"
    fi
  else
    TITULO="[$1] $2"
  fi
fi

# --- 2. Vía Konsole / QDBUS (KDE) --------------------------------------------
QDBUS=""
for c in qdbus6 qdbus qdbus-qt6 qdbus-qt5; do
  command -v "$c" >/dev/null 2>&1 && { QDBUS="$c"; break; }
done

if [ -n "$QDBUS" ]; then
  SERV="${KONSOLE_DBUS_SERVICE:-}"
  SESS="${KONSOLE_DBUS_SESSION:-}"
  VIA="Konsole D-Bus (env)"

  if [ -z "$SERV" ] || [ -z "$SESS" ]; then
    # Buscar konsole en los ancestros
    VIA="Konsole D-Bus (árbol de procesos)"
    p="${PPID:-$$}"
    kpid=""
    for _ in $(seq 1 15); do
      read -r pp cm <<<"$(ps -o ppid=,comm= -p "$p" 2>/dev/null)"
      [ -z "${cm:-}" ] && break
      [ "$cm" = "konsole" ] && { kpid="$p"; break; }
      p="$pp"
    done
    if [ -n "$kpid" ]; then
      SERV="org.kde.konsole-$kpid"
      SESS="$($QDBUS "$SERV" 2>/dev/null | grep -m1 '^/Sessions/' || true)"
    fi
  fi

  if [ -n "$SERV" ] && [ -n "$SESS" ]; then
    if [ "$MODO" = "leer" ]; then
      $QDBUS "$SERV" "$SESS" org.kde.konsole.Session.title 1 2>/dev/null || true
      exit 0
    fi
    $QDBUS "$SERV" "$SESS" org.kde.konsole.Session.setTitle 1 "$TITULO" >/dev/null 2>&1 || true
    ACTUAL=$($QDBUS "$SERV" "$SESS" org.kde.konsole.Session.title 1 2>/dev/null || true)
    if [ "$ACTUAL" = "$TITULO" ]; then
      echo "✅ Título puesto y verificado: «$ACTUAL» (vía $VIA)"
      exit 0
    fi
  fi
fi

# --- 3. Vía X11 (xdotool / wmctrl) — para AntiX / IceWM / Xterm -------------
if [ -n "${DISPLAY:-}" ]; then
  if command -v xdotool >/dev/null 2>&1; then
    WID="${WINDOWID:-}"
    if [ -z "$WID" ]; then
      WID=$(xdotool getactivewindow 2>/dev/null || true)
    fi
    if [ -n "$WID" ]; then
      if [ "$MODO" = "leer" ]; then
        xdotool getwindowname "$WID" 2>/dev/null || true
        exit 0
      fi
      xdotool set_window --name "$TITULO" "$WID" 2>/dev/null || true
      ACTUAL=$(xdotool getwindowname "$WID" 2>/dev/null || true)
      if [ -n "$ACTUAL" ]; then
        echo "✅ Título puesto en X11 (xdotool): «$ACTUAL»"
        exit 0
      fi
    fi
  fi

  if command -v wmctrl >/dev/null 2>&1; then
    if [ "$MODO" = "poner" ]; then
      wmctrl -r :ACTIVE: -N "$TITULO" 2>/dev/null || true
      echo "✅ Título enviado a ventana activa vía wmctrl: «$TITULO»"
      exit 0
    fi
  fi
fi

# --- 4. Fallback: Secuencia de escape ANSI / OSC -----------------------------
if [ "$MODO" = "poner" ]; then
  # Intentar escribir directo a terminal controladora si existe
  if [ -w /dev/tty ]; then
    printf '\033]0;%s\007' "$TITULO" > /dev/tty 2>/dev/null || true
  else
    printf '\033]0;%s\007' "$TITULO" || true
  fi
  echo "ℹ️ Título emitido vía secuencia ANSI OSC: «$TITULO»"
  exit 0
fi

exit 0
