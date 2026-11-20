#!/usr/bin/env bash
# kz-atencion.sh beat|status|mark <agente> <estado> — latido de atención (protocolo-cobertura.md)
# Umbrales: activo <10 min, ocupado <20 min, si no: caido. Estados forzados: sin_cuota, vigilia.
set -euo pipefail
D="$HOME/kz/presence/atencion"; mkdir -p "$D"
declare -A F=( [kz]="$D/kz.json" [nemo]="$HOME/nemo/presence/atencion/nemo.json" )
now=$(date +%s); iso=$(date -Iseconds)
case "${1:-status}" in
  beat)
    motor=$(grep -m1 'motor_activo' "$HOME/kz/presence/self.md" | sed 's/.*:\*\* *//')
    printf '{"agente":"kz","estado":"%s","motor":"%s","ultimo_latido":"%s","epoch":%s}\n' "${2:-activo}" "$motor" "$iso" "$now" > "${F[kz]}";;
  mark)
    a="${2:?agente}"; e="${3:?estado}"; f="${F[$a]:-$D/$a.json}"
    printf '{"agente":"%s","estado":"%s","marcado_por":"kz","ultimo_latido":"%s","epoch":%s}\n' "$a" "$e" "$iso" "$now" > "$f";;
  status)
    for a in kz nemo; do
      f="${F[$a]}"
      if [ ! -f "$f" ]; then echo "$a: sin latido"; continue; fi
      ep=$(python3 -c "import json;print(json.load(open('$f')).get('epoch') or 0)" 2>/dev/null || echo 0)
      st=$(python3 -c "import json;print(json.load(open('$f')).get('estado',''))" 2>/dev/null || echo "")
      if [ "$ep" = 0 ]; then ts=$(python3 -c "import json,datetime;print(int(datetime.datetime.fromisoformat(json.load(open('$f')).get('ultimo_latido')).timestamp()))" 2>/dev/null || echo 0); ep=$ts; fi
      m=$(( (now-ep)/60 ))
      case "$st" in sin_cuota|vigilia) r="$st";; *) if [ $m -lt 10 ]; then r=activo; elif [ $m -lt 20 ]; then r=ocupado; else r=caido; fi;; esac
      echo "$a: $r (latido hace ${m} min)"
    done;;
  *) echo "uso: $0 beat [estado]|status|mark <agente> <estado>"; exit 1;;
esac
