#!/usr/bin/env python3
"""Stream incoming ntfy messages to presence/stream.log so wake-once wakes on Lalo's messages.
Runs on all 4 sister machines (h310/Kz, pavilion/Pau, antix/Kora, 305v4/Samy).
"""

import json
import os
import time
import urllib.request
from pathlib import Path

HOME_DIR = Path(__file__).resolve().parent.parent
PRESENCE_DIR = HOME_DIR / "presence"
STREAM_PATH = PRESENCE_DIR / "stream.log"
LATEST_PATH = PRESENCE_DIR / "ntfy-latest.json"
SISTER_PREFIXES = ("Kz", "Pau", "Kora", "Samy")


def find_env_path() -> Path:
    cfg_root = Path.home() / ".config"
    for name in ("kz", "pau", "kora", "samy", "companion"):
        candidate = cfg_root / name / "ntfy.env"
        if candidate.exists():
            return candidate
    raise RuntimeError("ntfy.env not found in ~/.config/{kz,pau,kora,samy,companion}/")


def load_ntfy_url() -> str:
    env_path = find_env_path()
    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("NTFY_URL="):
            return line.split("=", 1)[1].strip().strip('"').strip("'")
    raise RuntimeError(f"NTFY_URL not found in {env_path}")


def main():
    url = load_ntfy_url().rstrip("/") + "/json"
    seen_ids: set[str] = set()
    start_ts = int(time.time())

    while True:
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "sister-ntfy-watch/1.0"})
            with urllib.request.urlopen(req, timeout=90) as resp:
                for raw in resp:
                    line = raw.decode("utf-8", errors="replace").strip()
                    if not line:
                        continue
                    try:
                        msg = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    if msg.get("event") != "message":
                        continue
                    msg_id = msg.get("id", "")
                    if not msg_id or msg_id in seen_ids:
                        continue
                    seen_ids.add(msg_id)
                    if int(msg.get("time", 0)) < start_ts:
                        continue
                    title = (msg.get("title") or "").strip()
                    if any(title.startswith(p) for p in SISTER_PREFIXES):
                        continue
                    text = (msg.get("message") or "").replace("\n", " ").strip()
                    PRESENCE_DIR.mkdir(parents=True, exist_ok=True)
                    LATEST_PATH.write_text(json.dumps(msg, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
                    with STREAM_PATH.open("a", encoding="utf-8") as sfh:
                        sfh.write(f"CHANGED: ntfy {text[:200]}\n")
        except Exception:
            time.sleep(5)


if __name__ == "__main__":
    main()
