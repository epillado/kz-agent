#!/usr/bin/env python3
"""Avisa cuando alguien más escribe en cualquier conversación de Slack.

Canales, privados, grupos y DMs, hilos incluidos. Slack los devuelve en la
búsqueda del día. La primera pasada solo guarda el cursor. El nombre del
archivo es el de antes; el alcance ya no es SAS ni PEAM.
"""
import importlib.util
import json
import time
import urllib.error
from pathlib import Path
from urllib.parse import quote

ME = "U09LMEFJDHT"
STATE = Path("/home/lalo/kz/presence/kz-cursors/slack-frentes.json")
LOG = Path("/home/lalo/kz/presence/kz-cursors/slack-watch.log")
GAP = 0.4
SWEEP_PAUSE = 20
GRACE = 20 * 60
SEEN_CAP = 2500


def client():
    spec = importlib.util.spec_from_file_location(
        "kzslack", "/home/lalo/kz/scripts/kz-slack-send.py"
    )
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.SlackClient()


def ts_key(ts):
    whole, _, frac = str(ts).partition(".")
    return (int(whole or 0), int(frac or 0))


def note(text):
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with LOG.open("a", encoding="utf-8") as handle:
        handle.write(text.rstrip() + "\n")


def call(api, endpoint):
    for _ in range(5):
        try:
            res = api.api_call(endpoint)
        except urllib.error.HTTPError as exc:
            if exc.code == 429:
                time.sleep(int(exc.headers.get("Retry-After") or 3))
                continue
            raise
        if res.get("ok"):
            return res
        if res.get("error") == "ratelimited":
            time.sleep(3)
            continue
        raise RuntimeError(res.get("error") or endpoint)
    raise RuntimeError("ratelimited")


def load_state():
    if not STATE.exists():
        return {"watermark": "0", "seen": [], "primed": False}
    raw = json.loads(STATE.read_text())
    if isinstance(raw, dict) and "watermark" in raw:
        raw.setdefault("seen", [])
        raw.setdefault("primed", True)
        return raw
    seen = []
    watermark = "0"
    if isinstance(raw, list):
        seen = [str(item) for item in raw]
        for item in seen:
            _, _, ts = item.partition(":")
            if ts and ts_key(ts) > ts_key(watermark):
                watermark = ts
    elif isinstance(raw, dict):
        for cid, slot in (raw.get("channels") or {}).items():
            cursor = (slot or {}).get("cursor") or ""
            if cursor and ts_key(cursor) > ts_key(watermark):
                watermark = cursor
            if cursor:
                seen.append(f"{cid}:{cursor}")
    return {"watermark": watermark, "seen": seen[-SEEN_CAP:], "primed": True}


def save_state(state):
    state["seen"] = state["seen"][-SEEN_CAP:]
    STATE.parent.mkdir(parents=True, exist_ok=True)
    tmp = STATE.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(state, ensure_ascii=False))
    tmp.replace(STATE)


def queries():
    days = [time.strftime("%Y-%m-%d")]
    if time.strftime("%H:%M") < "00:40":
        days.append(time.strftime("%Y-%m-%d", time.localtime(time.time() - 86400)))
    found = []
    for day in days:
        found.append(f"on:{day}")
        found.append(f"on:{day} is:dm")
        found.append(f"on:{day} is:mpim")
    return found


def search(api, query, state):
    found = []
    floor = ts_key(state.get("watermark") or "0")[0] - GRACE
    for page in range(1, 5):
        endpoint = (
            "search.messages?query="
            + quote(query)
            + f"&sort=timestamp&sort_dir=desc&count=80&page={page}"
        )
        res = call(api, endpoint)
        matches = ((res.get("messages") or {}).get("matches")) or []
        if not matches:
            break
        found.extend(matches)
        oldest = min(ts_key(item.get("ts") or "0")[0] for item in matches)
        if len(matches) < 80 or oldest < floor:
            break
        time.sleep(GAP)
    return found


def label(match):
    channel = match.get("channel") or {}
    cid = channel.get("id") or ""
    name = channel.get("name") or match.get("username") or cid or "?"
    if channel.get("is_im") or cid.startswith("D"):
        return "im:" + name
    if channel.get("is_mpim") or channel.get("is_mpim"):
        return "mpim:" + name
    if cid.startswith("G") and channel.get("is_private") and not channel.get("is_channel"):
        return "mpim:" + name
    return "#" + name.lstrip("#")


def key_of(match):
    channel = match.get("channel") or {}
    cid = channel.get("id") or "x"
    return f"{cid}:{match.get('ts')}"


def alertable(match):
    if match.get("user") == ME:
        return False
    text = match.get("text") or ""
    if not text.strip() and not match.get("files") and not match.get("attachments"):
        return False
    return True


def line(match):
    text = " ".join((match.get("text") or "").split())
    if not text and (match.get("files") or match.get("attachments")):
        text = "[archivo]"
    if len(text) > 140:
        text = text[:137] + "..."
    who = match.get("user") or match.get("username") or "alguien"
    return f"CHANGED: slack {label(match)} {match.get('ts')} {who} {text}"


def sweep(api, state):
    fresh = []
    seen = set(state.get("seen") or [])
    matches = []
    for query in queries():
        matches.extend(search(api, query, state))
        time.sleep(GAP)
    matches.sort(key=lambda item: ts_key(item.get("ts") or "0"))
    if not state.get("primed"):
        watermark = state.get("watermark") or "0"
        for match in matches:
            ts = match.get("ts")
            if ts and ts_key(ts) > ts_key(watermark):
                watermark = ts
            seen.add(key_of(match))
        state["watermark"] = watermark
        state["seen"] = list(seen)
        state["primed"] = True
        save_state(state)
        note(f"baseline {len(matches)} mensajes, marca {watermark}")
        return fresh
    watermark = state.get("watermark") or "0"
    floor = ts_key(watermark)[0] - GRACE
    for match in matches:
        ts = match.get("ts") or "0"
        if ts_key(ts)[0] < floor:
            continue
        key = key_of(match)
        if key in seen:
            continue
        seen.add(key)
        if alertable(match):
            fresh.append(line(match))
        if ts_key(ts) > ts_key(watermark):
            watermark = ts
    state["watermark"] = watermark
    state["seen"] = list(seen)
    save_state(state)
    note(f"pase {len(matches)} vistos, avisos {len(fresh)}")
    return fresh


def main():
    import sys

    once = "--once" in sys.argv
    api = client()
    state = load_state()
    while True:
        try:
            fresh = sweep(api, state)
        except Exception as exc:
            print(f"CHANGED: slack sensor {exc}", flush=True)
            note(f"sensor {exc}")
            if once:
                return
            time.sleep(SWEEP_PAUSE)
            continue
        for item in fresh:
            print(item, flush=True)
        if once:
            return
        time.sleep(SWEEP_PAUSE)


if __name__ == "__main__":
    main()
