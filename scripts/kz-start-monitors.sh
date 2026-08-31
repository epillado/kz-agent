#!/bin/bash
echo "Deteniendo monitores previos..."
~/kz/scripts/kz-presence-watch.sh stop 2>/dev/null || true
~/kz/scripts/kz-desktop-notif-watch.sh stop 2>/dev/null || true
~/kz/scripts/kz-notif-watch.sh stop 2>/dev/null || true
~/kz/scripts/kz-inbox-wake.sh stop 2>/dev/null || true
# flock queda puesto si el watch murió a KILL; sin esto el siguiente start no arranca
rm -f ~/kz/presence/notif/watch.lock

echo "Levantando stack..."
mkdir -p ~/kz/presence
touch ~/kz/presence/stream.log

# AntiX/IceWM (y cualquier caja sin Plasma): el sensor de Slack vive del bus FDO.
# Si nadie reclama org.freedesktop.Notifications, Slack no emite y notify-send falla.
if ! dbus-send --session --dest=org.freedesktop.DBus --type=method_call --print-reply \
     /org/freedesktop/DBus org.freedesktop.DBus.NameHasOwner \
     string:org.freedesktop.Notifications 2>/dev/null | grep -q 'boolean true'; then
  if [ -x /usr/libexec/notify-osd ]; then
    echo "Arrancando notify-osd (servidor de notificaciones)..."
    /usr/libexec/notify-osd >/dev/null 2>&1 &
    sleep 0.4
  elif command -v dunst >/dev/null 2>&1; then
    echo "Arrancando dunst (servidor de notificaciones)..."
    dunst >/dev/null 2>&1 &
    sleep 0.4
  else
    echo "AVISO: no hay servidor FDO Notifications (notify-osd/dunst). Slack quedará sordo."
  fi
fi
# Redirigir todos los monitores al log unificado para que el agente lo atrape con tail -f
# SOFT_PING=1 sin chat = “voltea a Grok” vacío (AGENTS: mal). Solo si Kz despierta y escribe.
KZ_PRESENCE_NUDGE=0 KZ_PRESENCE_SOFT_PING=0 nohup ~/kz/scripts/kz-presence-watch.sh >> ~/kz/presence/stream.log 2>&1 &
nohup ~/kz/scripts/kz-desktop-notif-watch.sh >> ~/kz/presence/stream.log 2>&1 &
nohup ~/kz/scripts/kz-notif-watch.sh >> ~/kz/presence/stream.log 2>&1 &
# Despertador del tubo CP (2026-08-28): tray+chat_owed cuando inbox-cp crece.
nohup ~/kz/scripts/kz-inbox-wake.sh >> ~/kz/presence/stream.log 2>&1 &

echo "Levantando timer de pausas oculares (20-20-20)..."
# Tray + chat_owed aunque el LLM no despierte (hueco 2026-08-26).
if [[ -f ~/kz/presence/ojos-loop.pid ]] && kill -0 "$(cat ~/kz/presence/ojos-loop.pid)" 2>/dev/null; then
  echo "ojos-loop ya vivo pid=$(cat ~/kz/presence/ojos-loop.pid)"
else
  nohup ~/kz/scripts/kz-ojos-loop.sh >> ~/kz/presence/stream.log 2>&1 &
fi

echo "Levantando decay de pico (host, sin LLM ni chat)..."
if [[ -f ~/kz/presence/pico-decay.pid ]] && kill -0 "$(cat ~/kz/presence/pico-decay.pid)" 2>/dev/null; then
  echo "pico-decay ya vivo pid=$(cat ~/kz/presence/pico-decay.pid)"
else
  nohup ~/kz/scripts/kz-pico-decay.sh loop >> ~/kz/presence/pico-decay.log 2>&1 &
fi

sleep 2

echo "Verificando procesos..."
PRESENCE=$(ps aux | grep -E 'kz-presence-watch' | grep -v grep | wc -l)
DESKTOP=$(ps aux | grep -E 'kz-desktop-notif' | grep -v grep | wc -l)
CELU=$(ps aux | grep -E 'kz-notif-watch' | grep -v grep | wc -l)

if [ "$PRESENCE" -ge 1 ] && [ "$DESKTOP" -ge 1 ] && [ "$CELU" -ge 1 ]; then
    echo "✅ Stack completo arriba y verificado."
    ps aux | grep -E 'python3|dbus-monitor|kz-presence|kz-notif|kz-desktop' | grep -v grep
    exit 0
else
    echo "❌ Error: Algunos procesos no levantaron."
    ps aux | grep -E 'python3|dbus-monitor|kz-presence|kz-notif|kz-desktop' | grep -v grep
    exit 1
fi
