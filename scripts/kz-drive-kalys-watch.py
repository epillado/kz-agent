#!/usr/bin/env python3
"""Sensor del canal Kalys en Google Drive.

Revisa la carpeta PKM cada 3 minutos. No escribe nada si no hay cambio,
y no usa el token CHANGED:: el feed de Grok ya sigue
presence/social/inbox-kalys.md y despierta solo con un encabezado ## nuevo.
No es un cron del modelo.
"""
from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path

KZ = Path.home() / "kz"
AUTH = Path("/mnt/DatosLinux/agent-homes/.grok/auth.json")
STATE = KZ / "presence" / "kz-cursors" / "drive-kalys.json"
LOG = KZ / "presence" / "drive-kalys-watch.log"
INBOX = KZ / "presence" / "social" / "inbox-kalys.md"
PKM = "1xP7SmtIkGb4gsXnArF85Mz-xXD6NJMlw"
INTERVAL = 180
GATEWAY = "https://cli-chat-proxy.grok.com/v1/mcp/tools/call"
LIST = "cursor__bridge___user-Google-drive-list_5ffolder___17"
READ = "cursor__bridge___user-Google-drive-read_5ffile___17"


def log(msg: str) -> None:
    LOG.parent.mkdir(parents=True, exist_ok=True)
    line = f"{datetime.now().isoformat(timespec='seconds')} {msg}\n"
    with LOG.open("a", encoding="utf-8") as fh:
        fh.write(line)


def token() -> str:
    data = json.loads(AUTH.read_text(encoding="utf-8"))
    return next(iter(data.values()))["key"]


def call(call_id: str, args: dict) -> dict:
    body = json.dumps({"call_id": call_id, "arguments": args}).encode()
    req = urllib.request.Request(
        GATEWAY,
        data=body,
        headers={
            "Authorization": f"Bearer {token()}",
            "X-XAI-Token-Auth": "xai-grok-cli",
            "x-grok-client-version": "1.0.70",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=70) as resp:
        payload = json.loads(resp.read())
    result = payload.get("result") or {}
    text = "".join(part.get("text") or "" for part in result.get("content") or [])
    if result.get("isError"):
        raise RuntimeError(text[:500])
    if not text:
        return {}
    return json.loads(text)


def list_pkm() -> dict[str, dict]:
    found: dict[str, dict] = {}
    page = None
    while True:
        args = {"folderId": PKM, "pageSize": 100}
        if page:
            args["pageToken"] = page
        data = call(LIST, args)
        for item in data.get("files") or []:
            fid = item.get("id") or item.get("fileId")
            if not fid or item.get("trashed"):
                continue
            found[fid] = {
                "name": item.get("name") or fid,
                "modifiedTime": item.get("modifiedTime") or "",
                "mimeType": item.get("mimeType") or "",
            }
        page = data.get("nextPageToken")
        if not page:
            break
    return found


def snippet(fid: str) -> str:
    try:
        head = call(READ, {"fileId": fid, "startLine": 1, "endLine": 1, "maxChars": 40})
        total = int(head.get("totalLines") or 1)
        start = max(1, total - 25)
        data = call(READ, {"fileId": fid, "startLine": start, "maxChars": 1200})
    except Exception as exc:
        return f"(no pude leer el texto: {exc})"
    content = (data.get("content") or "").strip()
    if not content:
        return "(el archivo cambió y no trajo texto nuevo)"
    if len(content) > 900:
        content = content[:900].rstrip() + "…"
    return content


def load_state() -> dict:
    if not STATE.exists():
        return {}
    try:
        return json.loads(STATE.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}


def save_state(files: dict[str, dict]) -> None:
    STATE.parent.mkdir(parents=True, exist_ok=True)
    blob = {"updated": datetime.now().isoformat(timespec="seconds"), "files": files}
    tmp = STATE.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(blob, ensure_ascii=False), encoding="utf-8")
    tmp.replace(STATE)


def wake(changes: list[tuple[str, dict, str]]) -> None:
    INBOX.parent.mkdir(parents=True, exist_ok=True)
    now = datetime.now().strftime("%H:%M")
    lines = [f"\n## {now} — Kalys (Drive)\n"]
    if len(changes) > 5:
        names = ", ".join(item[1]["name"] for item in changes[:12])
        lines.append(
            f"Se movieron {len(changes)} archivos en PKM. Los primeros: {names}.\n"
        )
    else:
        for fid, meta, kind in changes:
            lines.append(f"{kind}: `{meta['name']}` ({meta['modifiedTime']}).\n")
            if "folder" not in meta.get("mimeType", ""):
                lines.append(snippet(fid))
                lines.append("\n")
    lines.append("\n")
    with INBOX.open("a", encoding="utf-8") as fh:
        fh.write("\n".join(lines))


def cycle(baseline: bool) -> None:
    current = list_pkm()
    state = load_state()
    previous = state.get("files") or {}
    if previous and len(current) < max(1, int(len(previous) * 0.5)):
        log(f"lista corta {len(current)} contra {len(previous)}, no aviso")
        return
    if baseline or not previous:
        save_state(current)
        log(f"baseline {len(current)} archivos, sin aviso")
        return
    changes = []
    for fid, meta in current.items():
        old = previous.get(fid)
        if old is None:
            changes.append((fid, meta, "nuevo"))
        elif old.get("modifiedTime") != meta.get("modifiedTime"):
            changes.append((fid, meta, "cambió"))
    if not changes:
        return
    # Guarda el largo anterior solo si ya lo teníamos. No bloquea el aviso.
    wake(changes)
    save_state(current)
    log("aviso " + ", ".join(meta["name"] for _, meta, _ in changes[:8]))


def main() -> int:
    log("arriba, cada 180 s, PKM de Kalys")
    first = True
    while True:
        try:
            cycle(first)
            first = False
        except Exception as exc:
            log(f"error {type(exc).__name__}: {exc}")
        time.sleep(INTERVAL)


if __name__ == "__main__":
    sys.exit(main())
