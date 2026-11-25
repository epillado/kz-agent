#!/usr/bin/env python3
"""Pull today's Garmin Connect health summary using saved OAuth tokens and replicate to active sisters."""

import json
import os
import subprocess
import sys
from datetime import date, datetime, timezone
from pathlib import Path

try:
    from garminconnect import Garmin
except ImportError:
    venv_py = Path.home() / ".local" / "share" / "garmin-venv" / "bin" / "python3"
    if venv_py.exists() and Path(sys.executable).resolve() != venv_py.resolve():
        os.execv(str(venv_py), [str(venv_py), __file__, *sys.argv[1:]])
    raise

HOME_DIR = Path(__file__).resolve().parent.parent
OUT_PATH = HOME_DIR / "presence" / "garmin-latest.json"

SISTER_TARGETS = [
    ("h310", "~/kz/presence"),             # h310 (Kz)
    ("pavilion", "~/companion/presence"),  # pavilion (Pau)
    ("antix", "~/companion/presence"),     # antix (Kora)
    ("305v4", "~/companion/presence"),     # 305v4 (Samy)
]


def find_config_dir() -> Path:
    cfg_root = Path.home() / ".config"
    for name in ("kz", "pau", "kora", "samy", "companion"):
        candidate = cfg_root / name
        if (candidate / "garth").exists() or (candidate / "garmin.env").exists():
            return candidate
    return cfg_root / "pau"


def load_env(env_path: Path) -> dict:
    env = {}
    if env_path.exists():
        for line in env_path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                env[k.strip()] = v.strip().strip('"').strip("'")
    return env


def replicate_to_sisters(payload_str: str) -> None:
    local_hostname = os.uname().nodename.lower()
    for host, remote_dir in SISTER_TARGETS:
        if host in local_hostname:
            continue
        try:
            subprocess.Popen(
                [
                    "ssh",
                    "-o", "BatchMode=yes",
                    "-o", "ConnectTimeout=2",
                    host,
                    f"mkdir -p {remote_dir} && cat > {remote_dir}/garmin-latest.json",
                ],
                stdin=subprocess.PIPE,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            ).communicate(input=payload_str.encode("utf-8"), timeout=4)
        except Exception:
            pass


def main():
    config_dir = find_config_dir()
    tokenstore = str(config_dir / "garth")
    env_path = config_dir / "garmin.env"
    env = load_env(env_path)
    client = Garmin(env.get("GARMIN_EMAIL", ""), env.get("GARMIN_PASSWORD", ""))
    try:
        client.login(tokenstore)
    except Exception:
        if not env.get("GARMIN_EMAIL") or not env.get("GARMIN_PASSWORD"):
            raise
        client.login()
        os.makedirs(tokenstore, mode=0o700, exist_ok=True)
        client.garth.dump(tokenstore)

    today = date.today().isoformat()
    summary = client.get_user_summary(today)
    hr = client.get_heart_rates(today)
    sleep = client.get_sleep_data(today)

    out = {
        "fetched_at": datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds"),
        "date": today,
        "resting_hr": summary.get("restingHeartRate"),
        "min_hr": summary.get("minHeartRate"),
        "max_hr": summary.get("maxHeartRate"),
        "steps": summary.get("totalSteps"),
        "stress_avg": summary.get("averageStressLevel"),
        "bb_charged": summary.get("bodyBatteryChargedValue"),
        "bb_drained": summary.get("bodyBatteryDrainedValue"),
        "bb_most_recent": summary.get("bodyBatteryMostRecentValue"),
        "last_sync": summary.get("lastSyncTimestampGMT"),
        "sleep_seconds": (sleep.get("dailySleepDTO") or {}).get("sleepTimeSeconds"),
        "sleep_score": ((sleep.get("dailySleepDTO") or {}).get("sleepScores") or {}).get("overall", {}).get("value"),
        "hr_values_count": len(hr.get("heartRateValues") or []),
        "latest_hr_sample": (hr.get("heartRateValues") or [None])[-1],
    }
    payload_str = json.dumps(out, indent=2, ensure_ascii=False) + "\n"
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(payload_str, encoding="utf-8")
    replicate_to_sisters(payload_str)
    print(payload_str, end="")


if __name__ == "__main__":
    main()
