#!/usr/bin/env python3
"""Despertador Agy / Claude / Codex: un evento, una línea CHANGED:, exit 0.

No usar grok-feed | head (subshell + pipefail: el proceso no muere).
El runtime despierta al LLM cuando ESTE proceso termina.
"""
from __future__ import annotations

import base64
import json
import os
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

HOME = Path(os.environ.get("WAKE_HOME") or Path(__file__).resolve().parents[1])
PRESENCE = HOME / "presence"
SOCIAL = PRESENCE / "social"
INTERVAL = float(os.environ.get("WAKE_ONCE_INTERVAL", "0.5"))
BEAT_INTERVAL = 180.0


def get_bb_open_prs() -> dict[str, str]:
    """Lee PRs abiertos en peam-frontend y peam-backend vía Bitbucket API."""
    env_file = Path.home() / "Workspace" / "sas-backend-core" / ".env"
    token = os.environ.get("BB_API_TOKEN", "")
    if not token and env_file.exists():
        for line in env_file.read_text(encoding="utf-8", errors="ignore").splitlines():
            if line.startswith("BB_API_TOKEN="):
                token = line.split("=", 1)[1].strip().strip("\"'")
                break
    if not token:
        return {}
    auth = base64.b64encode(f"eduardo.pillado@redts.lat:{token}".encode()).decode()
    out: dict[str, str] = {}
    for repo in ("peam-frontend", "peam-backend"):
        url = f"https://api.bitbucket.org/2.0/repositories/redts/{repo}/pullrequests?state=OPEN"
        try:
            req = urllib.request.Request(url, headers={"Authorization": f"Basic {auth}"})
            data = json.loads(urllib.request.urlopen(req, timeout=6).read().decode())
            for pr in data.get("values", []):
                pr_id = pr.get("id")
                sha = (pr.get("source", {}).get("commit", {}).get("hash") or "")[:7]
                title = pr.get("title", "")
                out[f"{repo}#{pr_id}"] = f"{sha} {title}"
        except Exception:
            pass
    return out


def watch_paths() -> list[Path]:
    paths = [
        PRESENCE / "stream.log",
        PRESENCE / "notif" / "changed.log",
    ]
    SOCIAL.mkdir(parents=True, exist_ok=True)
    (PRESENCE / "notif").mkdir(parents=True, exist_ok=True)
    paths.extend(sorted(SOCIAL.glob("inbox-*.md")))
    kalys_inbox = Path("/mnt/DatosLinux/Workspace/playbook/PKM/inbox-kalys.md")
    paths.append(kalys_inbox)
    for role_buzon in [
        Path("/home/lalo/Workspace/playbook/PKM/20260901-GOV-buzon_rol_kb-ex.md"),
    ]:
        if role_buzon.exists():
            paths.append(role_buzon)
    for p in paths:
        p.parent.mkdir(parents=True, exist_ok=True)
        if not p.exists():
            p.touch()
    return paths


def snapshot(paths: list[Path]) -> dict[Path, int]:
    out: dict[Path, int] = {}
    for p in paths:
        try:
            out[p] = p.stat().st_size
        except OSError:
            out[p] = 0
    return out


def relevant(path: Path, delta: str) -> bool:
    if not delta:
        return False
    if path.name.startswith("inbox-") or "buzon_rol_" in path.name or path.name.endswith(".headless.log"):
        return True
    if "leveldb" in str(path) and "xoxc-" in delta:
        return True
    no_slack = (PRESENCE / "no-slack.mode").exists() or os.environ.get("KZ_NO_SLACK") == "1"
    if no_slack and ("slack_hot" in delta or "desktop_seen" in delta or "notif:important:" in delta or "buzón-rol" in delta):
        return False
    for raw in delta.splitlines():
        line = raw.strip()
        if "CHANGED:" not in line:
            continue
        # Ignorar ecos internos de Puente Radar hacia Tridente/minuta-ex o error repetido de sesión Slack
        if (
            "notif:important:Tridente:" in line
            or "slack sensor invalid_auth" in line
            or "slack sensor internal_error" in line
            or "notif:important:KDE Connect:" in line
            or "soporte-qualitas" in line
            or "redts-providers-alerts" in line
            or "notif:slack_hot:Slack:New message in secretaria-de-economia" in line
        ):
            continue
        after = line.split("CHANGED:", 1)[1].strip()
        labels = [lbl.strip() for lbl in after.split(",") if lbl.strip()]
        if labels and all(lbl in {"bitácora", "buzón-rol", "pkm"} for lbl in labels):
            continue
        return True
    return False


def preview(delta: str) -> str:
    for raw in delta.splitlines():
        line = raw.strip()
        if line:
            return line[:160]
    return delta.strip().replace("\n", " ")[:160]


def main() -> int:
    paths = watch_paths()
    cursors = snapshot(paths)
    bb_prs = get_bb_open_prs()
    last_beat = time.monotonic()
    beat_cmd = str(HOME / "scripts" / "kz-atencion.sh")
    while True:
        time.sleep(INTERVAL)
        now = time.monotonic()
        if now - last_beat >= BEAT_INTERVAL:
            last_beat = now
            try:
                subprocess.run([beat_cmd, "beat"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=3)
            except Exception:
                pass
            cur_prs = get_bb_open_prs()
            if bb_prs:
                for k, v in cur_prs.items():
                    if k not in bb_prs or bb_prs.get(k) != v:
                        print(f"CHANGED: bitbucket: {k} -> {v}", flush=True)
                        return 0
            bb_prs.update(cur_prs)
        paths = watch_paths()
        for p in paths:
            try:
                size = p.stat().st_size
            except OSError:
                continue
            prev = cursors.get(p, 0)
            if size < prev:
                cursors[p] = size
                continue
            if size == prev:
                continue
            try:
                with p.open("r", encoding="utf-8", errors="replace") as fh:
                    fh.seek(prev)
                    delta = fh.read()
            except OSError:
                cursors[p] = size
                continue
            cursors[p] = size
            if not relevant(p, delta):
                continue
            print(f"CHANGED: {p.name}: {preview(delta)}", flush=True)
            return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(0)
