#!/usr/bin/env python3
"""kz-wake-once.py: Despertador reactivo por evento.
Duerme en segundo plano y sale con código 0 de inmediato ante la primera línea nueva relevante.
"""
import os
import sys
import time
from pathlib import Path

KZ_HOME = Path(__file__).resolve().parents[1]
WATCH_FILES = [
    KZ_HOME / "presence" / "stream.log",
    KZ_HOME / "presence" / "notif" / "changed.log",
    KZ_HOME / "presence" / "social" / "inbox-cp.md",
    KZ_HOME / "presence" / "social" / "inbox-kora.md",
    KZ_HOME / "presence" / "social" / "inbox-samy.md",
]

for p in WATCH_FILES:
    p.parent.mkdir(parents=True, exist_ok=True)
    if not p.exists():
        p.touch()

cursors = {}
for p in WATCH_FILES:
    try:
        cursors[p] = p.stat().st_size
    except OSError:
        cursors[p] = 0

while True:
    time.sleep(0.4)
    for p in WATCH_FILES:
        try:
            curr_size = p.stat().st_size
        except OSError:
            continue
        prev_size = cursors.get(p, 0)
        if curr_size > prev_size:
            try:
                with p.open("r", encoding="utf-8", errors="replace") as f:
                    f.seek(prev_size)
                    content = f.read()
            except OSError:
                content = ""
            cursors[p] = curr_size
            if content:
                line_preview = content.strip().replace("\n", " ")[:120]
                if "inbox" in p.name:
                    print(f"CHANGED: {p.name}: {line_preview}", flush=True)
                    sys.exit(0)
                elif "CHANGED:" in content or "timer-ojos" in content:
                    print(f"{line_preview}", flush=True)
                    sys.exit(0)
