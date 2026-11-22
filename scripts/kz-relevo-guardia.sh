#!/usr/bin/env bash
# kz-relevo-guardia.sh — Relevo atómico y verificado de guardia entre h310 (Kz) y pavilion (Pau)
# Uso: ~/kz/scripts/kz-relevo-guardia.sh {pavilion|pavilion-supervisada|h310}
set -euo pipefail

MODE="${1:-}"
if [[ "$MODE" != "pavilion" && "$MODE" != "pavilion-supervisada" && "$MODE" != "h310" ]]; then
    echo "Uso: $0 {pavilion|pavilion-supervisada|h310}" >&2
    exit 1
fi

NOW="$(date -Iseconds)"

if [[ "$MODE" == "pavilion" || "$MODE" == "pavilion-supervisada" ]]; then
    echo "=== 1. Sincronizando Playbook (h310 -> origin -> pavilion) antes del relevo ==="
    cd ~/Workspace/playbook
    if [[ -n "$(git status --porcelain)" ]]; then
        git add -A && git commit -m "sync(relevo-${MODE}): playbook antes de cambio de guardia (${NOW})" || true
    fi
    git pull --rebase -q origin main || true
    git push -q origin HEAD || true

    # En pavilion-supervisada h310 sigue encendida (Tridente corre en h310 vía SSH proxy desde pavilion).
    # En pavilion (h310 se apaga), Tridente pasa a correr localmente en pavilion.
    if [[ "$MODE" == "pavilion" ]]; then
        TRIDENTE_HOST="pavilion"
        mkdir -p ~/.cache/cp-buzones
        echo -e "active=1\nactive_host=pavilion\nupdated=${NOW}\nreason=Guardia nocturna autónoma en Pavilion" > ~/.cache/cp-buzones/no-tridente.mode
    else
        TRIDENTE_HOST="h310"
        rm -f ~/.cache/cp-buzones/no-tridente.mode
    fi

    echo "=== 2. Preflight en Pavilion (playbook sync, repos, Cyrus bridge, no-slack.mode, tridente host=${TRIDENTE_HOST}) ==="
    ssh -o ConnectTimeout=5 pavilion "
        set -e
        cd ~/Workspace/playbook
        git fetch origin -q && git reset --hard origin/main -q
        for r in peam-ex tlc-ex sas kb-ex daily-ex minuta-ex qualitas-ex hm; do
            TRIDENTE_ALLOW_LOCAL=1 tools/tridente/tridente buzon ack \$r --como \$r >/dev/null 2>&1 || true
        done
        TRIDENTE_ALLOW_LOCAL=1 tools/tridente/tridente buzon ack tridente --como pau >/dev/null 2>&1 || true
        mkdir -p ~/.cache/cp-buzones
        if [ '${TRIDENTE_HOST}' = 'pavilion' ]; then
            rm -f ~/.cache/cp-buzones/no-tridente.mode
        else
            echo -e 'active=1\nactive_host=h310\nupdated=${NOW}\nreason=Supervisión activa desde h310' > ~/.cache/cp-buzones/no-tridente.mode
        fi
        rm -f ~/companion/presence/no-slack.mode
        echo -e 'active=1\ncontrol=total\nsupervisor=kz\nupdated=${NOW}' > ~/companion/presence/puente-radar.mode
        systemctl --user is-active cyrus-inbox-bridge.service >/dev/null && echo '✅ cyrus-inbox-bridge: active' || (systemctl --user restart cyrus-inbox-bridge.service && echo '🔄 cyrus-inbox-bridge: restarted')
        for r in ~/Workspace/peam-backend ~/Workspace/peam-frontend ~/Workspace/sas-backend-core ~/Workspace/sas-frontend-web ~/Workspace/tlc-g2-backend-core-backend ~/Workspace/hecho-en-mexico-frontend; do
            if [ -d \"\$r/.git\" ]; then
                git -C \"\$r\" fetch --all --prune -q || true
                br=\$(git -C \"\$r\" branch --show-current)
                st=\$(git -C \"\$r\" status --porcelain)
                if [ \"\$br\" = \"develop\" ] && [ -z \"\$st\" ]; then
                    git -C \"\$r\" pull --ff-only -q origin develop || true
                fi
            fi
        done
        echo '✅ Playbook y Repos en Pavilion sincronizados; Tridente host=${TRIDENTE_HOST}'
    "
    echo -e "active=1\nupdated=${NOW}\nreason=Guardia en Pavilion (${MODE})" > ~/kz/presence/no-slack.mode
    echo "✅ Candado no-slack.mode activado en h310 (Pavilion es único emisor Slack; Tridente host=${TRIDENTE_HOST})"
else
    echo "=== Relevo hacia h310 (Kz Control Total + Tridente en h310) ==="
    ssh -o ConnectTimeout=5 pavilion "
        cd ~/Workspace/playbook
        if [ -n \"\$(git status --porcelain)\" ]; then
            git add -A && git commit -m 'sync(relevo-h310): playbook desde pavilion (${NOW})' && git push -q origin HEAD || true
        fi
        mkdir -p ~/.cache/cp-buzones
        echo -e 'active=1\nactive_host=h310\nupdated=${NOW}\nreason=Control Total en h310 (Kz)' > ~/.cache/cp-buzones/no-tridente.mode
        echo -e 'active=1\nupdated=${NOW}\nreason=Control Total en h310 (Kz)' > ~/companion/presence/no-slack.mode
    " || true
    cd ~/Workspace/playbook && git pull --rebase -q origin main || true
    for r in peam-ex tlc-ex sas kb-ex daily-ex minuta-ex qualitas-ex hm; do
        TRIDENTE_ALLOW_LOCAL=1 tools/tridente/tridente buzon ack "$r" --como "$r" >/dev/null 2>&1 || true
    done
    rm -f ~/.cache/cp-buzones/no-tridente.mode
    rm -f ~/kz/presence/no-slack.mode
    echo -e "active=1\ncontrol=total\nupdated=${NOW}" > ~/kz/presence/puente-radar.mode
    echo "✅ Control Total, Tridente y Slack activos en h310; Pavilion en no-slack.mode y no-tridente.mode (proxy SSH -> h310)"
fi
