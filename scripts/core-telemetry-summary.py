#!/usr/bin/env python3
"""Compact telemetry summary (Garmin + OwnTracks + ntfy) for session-pack and world status."""

import json
import time
from datetime import datetime
from pathlib import Path

HOME_DIR = Path(__file__).resolve().parent.parent
PRESENCE_DIR = HOME_DIR / "presence"
GARMIN_PATH = PRESENCE_DIR / "garmin-latest.json"
LOC_PATH = PRESENCE_DIR / "location-latest.json"
NTFY_PATH = PRESENCE_DIR / "ntfy-latest.json"


def fmt_garmin() -> str:
    if not GARMIN_PATH.exists():
        return "- **garmin:** (sin datos aún)"
    try:
        d = json.loads(GARMIN_PATH.read_text(encoding="utf-8"))
    except Exception:
        return "- **garmin:** (error leyendo garmin-latest.json)"

    bb = d.get("bb_most_recent")
    bb_c = d.get("bb_charged")
    bb_d = d.get("bb_drained")
    bb_str = f"{bb}" if bb is not None else "?"
    if bb_c is not None or bb_d is not None:
        bb_str += f" (+{bb_c or 0}/-{bb_d or 0})"

    rhr = d.get("resting_hr")
    sample = d.get("latest_hr_sample")
    hr_str = "?"
    now_ms = int(time.time() * 1000)
    if isinstance(sample, list) and len(sample) == 2 and sample[1] is not None:
        ts_ms, bpm = sample[0], sample[1]
        age_min = max(0, int((now_ms - int(ts_ms)) / 60000)) if ts_ms else 0
        sample_time = datetime.fromtimestamp(int(ts_ms) / 1000).strftime("%H:%M") if ts_ms else "?"
        if age_min > 45:
            hr_str = f"{bpm} bpm @ {sample_time} (hace {age_min}m — reloj en cargador o pendiente sync)"
        else:
            hr_str = f"{bpm} bpm @ {sample_time}"
    else:
        hr_str = "sin pulso actual (reloj en cargador o fuera de muñeca)"

    if rhr is not None:
        hr_str += f" [reposo {rhr}]"

    steps = d.get("steps")
    steps_str = f"{steps:,}" if isinstance(steps, int) else str(steps or "?")
    stress = d.get("stress_avg")
    stress_str = str(stress) if stress is not None else "?"

    sleep_s = d.get("sleep_seconds")
    sleep_score = d.get("sleep_score")
    if isinstance(sleep_s, (int, float)) and sleep_s > 0:
        h = int(sleep_s // 3600)
        m = int((sleep_s % 3600) // 60)
        sleep_str = f"{h}h{m:02d}m"
        if sleep_score is not None:
            sleep_str += f" (score {sleep_score})"
    else:
        sleep_str = "sin registro hoy"

    date_str = d.get("date", "?")
    return (
        f"- **biometría (Garmin {date_str}):** BodyBattery={bb_str} | "
        f"FC={hr_str} | estrés={stress_str} | pasos={steps_str} | sueño={sleep_str}"
    )


def fmt_location() -> str:
    if not LOC_PATH.exists():
        return "- **ubicación (OwnTracks):** (sin datos aún)"
    try:
        d = json.loads(LOC_PATH.read_text(encoding="utf-8"))
    except Exception:
        return "- **ubicación (OwnTracks):** (error leyendo location-latest.json)"

    regions = d.get("inregions") or []
    if regions:
        where = ", ".join(regions)
    else:
        lat = d.get("lat")
        lon = d.get("lon")
        where = f"fuera de geocerca ({lat}, {lon})" if lat is not None else "desconocida"

    batt = d.get("batt")
    bs = d.get("bs")
    bs_map = {1: "descargando", 2: "cargando ⚡", 3: "100% lleno"}
    batt_str = f"{batt}%" if batt is not None else "?"
    if bs in bs_map:
        batt_str += f" ({bs_map[bs]})"

    conn = d.get("conn")
    conn_map = {"w": "WiFi", "m": "Datos móviles", "o": "Offline"}
    conn_str = conn_map.get(conn, str(conn or "?"))

    rec = d.get("received_at", "?")
    if "T" in rec:
        rec = rec.split("T", 1)[1][:5]

    return f"- **ubicación (OwnTracks @ {rec}):** {where} | Reno12 bat={batt_str} | red={conn_str}"


def fmt_ntfy() -> str | None:
    if not NTFY_PATH.exists():
        return None
    try:
        d = json.loads(NTFY_PATH.read_text(encoding="utf-8"))
        ts = d.get("time")
        t_str = datetime.fromtimestamp(int(ts)).strftime("%Y-%m-%d %H:%M") if ts else "?"
        msg = (d.get("message") or "").replace("\n", " ").strip()
        if msg:
            return f"- **último ntfy ({t_str}):** {msg[:140]}"
    except Exception:
        pass
    return None


def main() -> None:
    print(fmt_garmin())
    print(fmt_location())
    ntfy_line = fmt_ntfy()
    if ntfy_line:
        print(ntfy_line)


if __name__ == "__main__":
    main()
