#!/bin/bash
echo "Deteniendo monitores previos..."
~/kz/scripts/kz-presence-watch.sh stop 2>/dev/null || true
~/kz/scripts/kz-desktop-notif-watch.sh stop 2>/dev/null || true
~/kz/scripts/kz-notif-watch.sh stop 2>/dev/null || true

echo "Levantando stack..."
mkdir -p ~/kz/presence
touch ~/kz/presence/stream.log
# Redirigir todos los monitores al log unificado para que el agente lo atrape con tail -f
KZ_PRESENCE_NUDGE=0 KZ_PRESENCE_SOFT_PING=1 nohup ~/kz/scripts/kz-presence-watch.sh >> ~/kz/presence/stream.log 2>&1 &
nohup ~/kz/scripts/kz-desktop-notif-watch.sh >> ~/kz/presence/stream.log 2>&1 &
nohup ~/kz/scripts/kz-notif-watch.sh >> ~/kz/presence/stream.log 2>&1 &

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
