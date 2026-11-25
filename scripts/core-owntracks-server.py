#!/usr/bin/env python3
"""Minimal Tailscale-only HTTP receiver for OwnTracks location pings.
Replicates location-latest.json and transition events across all 4 sister machines (Kz, Pau, Kora, Samy).
"""

import json
import os
import subprocess
import threading
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

BIND_HOST = os.environ.get("OWNTRACKS_HOST", "0.0.0.0")
BIND_PORT = int(os.environ.get("OWNTRACKS_PORT", "8085"))
PRESENCE_DIR = Path(__file__).resolve().parent.parent / "presence"
LATEST_PATH = PRESENCE_DIR / "location-latest.json"
LOG_PATH = PRESENCE_DIR / "location-log.jsonl"

SISTER_TARGETS = [
    ("h310", "~/kz/presence"),             # h310 (Kz)
    ("pavilion", "~/companion/presence"),  # pavilion (Pau)
    ("antix", "~/companion/presence"),     # antix (Kora)
    ("305v4", "~/companion/presence"),     # 305v4 (Samy)
]


def fanout_to_sisters(latest_json: str | None, transition_line: str | None) -> None:
    local_hostname = os.uname().nodename.lower()
    for host, remote_dir in SISTER_TARGETS:
        if host in local_hostname:
            continue
        try:
            if latest_json:
                p = subprocess.Popen(
                    [
                        "ssh",
                        "-o", "BatchMode=yes",
                        "-o", "ConnectTimeout=2",
                        host,
                        f"mkdir -p {remote_dir} && cat > {remote_dir}/location-latest.json",
                    ],
                    stdin=subprocess.PIPE,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
                p.communicate(input=latest_json.encode("utf-8"), timeout=4)
            if transition_line:
                p2 = subprocess.Popen(
                    [
                        "ssh",
                        "-o", "BatchMode=yes",
                        "-o", "ConnectTimeout=2",
                        host,
                        f"mkdir -p {remote_dir} && cat >> {remote_dir}/stream.log",
                    ],
                    stdin=subprocess.PIPE,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
                p2.communicate(input=transition_line.encode("utf-8"), timeout=4)
        except Exception:
            pass


class OwnTracksHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path not in ("/pub", "/pub/"):
            self.send_response(404)
            self.end_headers()
            return

        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length) if length > 0 else b""
        try:
            payload = json.loads(raw.decode("utf-8")) if raw else {}
        except Exception:
            self.send_response(400)
            self.end_headers()
            return

        now_iso = datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")
        record = {
            "received_at": now_iso,
            "remote_ip": self.client_address[0],
            **payload,
        }

        PRESENCE_DIR.mkdir(parents=True, exist_ok=True)
        with LOG_PATH.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(record, ensure_ascii=False) + "\n")

        latest_json = None
        transition_line = None

        if payload.get("_type") == "location":
            latest_json = json.dumps(record, ensure_ascii=False, indent=2) + "\n"
            LATEST_PATH.write_text(latest_json, encoding="utf-8")
        elif payload.get("_type") == "transition":
            event = payload.get("event", "?")
            desc = payload.get("desc", "zona")
            transition_line = f"CHANGED: location {event} {desc} ({now_iso})\n"
            stream = PRESENCE_DIR / "stream.log"
            with stream.open("a", encoding="utf-8") as sfh:
                sfh.write(transition_line)

        if latest_json or transition_line:
            threading.Thread(
                target=fanout_to_sisters,
                args=(latest_json, transition_line),
                daemon=True,
            ).start()

        body = b"[]"
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/health":
            body = b'{"ok":true}\n'
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        self.send_response(404)
        self.end_headers()

    def log_message(self, format, *args):
        return


def main():
    server = ThreadingHTTPServer((BIND_HOST, BIND_PORT), OwnTracksHandler)
    print(f"OwnTracks receiver listening on http://{BIND_HOST}:{BIND_PORT}/pub", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
