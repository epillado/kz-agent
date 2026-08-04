#!/usr/bin/env python3
"""
Escucha notificaciones de escritorio vía `dbus-monitor` (eavesdrop de Notify).
- stream.log: ve TODO (incl. Slack) sin spamear al agente
- pending + CHANGED: solo importante (Slack hot, mail trabajo, etc.)

Uso:
  kz-desktop-notif-watch.py         # loop
  kz-desktop-notif-watch.py stop
"""
from __future__ import annotations

import hashlib
import os
import re
import signal
import subprocess
import sys
from datetime import datetime
from pathlib import Path

KZ_HOME = Path(os.environ.get("KZ_HOME", Path.home() / "kz"))
NOTIF_DIR = KZ_HOME / "presence" / "notif"
FILTERS = NOTIF_DIR / "filters.env"
STREAM = NOTIF_DIR / "stream.log"
SEEN = NOTIF_DIR / "desktop_seen.tsv"
EVENTS = NOTIF_DIR / "events.log"
PENDING = NOTIF_DIR / "pending.md"
PENDING_TS = NOTIF_DIR / "pending.ts"
PENDING_LABELS = NOTIF_DIR / "pending_labels.txt"
CHANGED_LOG = NOTIF_DIR / "changed.log"  # cola de wake para el monitor del agente
PIDFILE = NOTIF_DIR / "desktop-watch.pid"


def load_filters() -> dict[str, str]:
    defaults = {
        "KZ_NOTIF_APP_IMPORTANT": r"Phone|Teléfono|Messages|Mensajes|SMS|Signal|WhatsApp|Telegram",
        "KZ_NOTIF_KW_IMPORTANT": r"Missed call|llamada|Incoming call|voicemail|urgente|urgent",
        "KZ_NOTIF_APP_MAIL": r"Gmail|Email|Correo|Outlook",
        "KZ_NOTIF_KW_MAIL": r"Josué|Josue|jmata|SECON|Elizeth|factura|VPN|Stephanie|RCA|P0|SLA",
        "KZ_NOTIF_BLOCK": r"Mercado Pago|promoci|oferta|Facebook|Instagram|TikTok|TELCEL|recarga",
        "KZ_NOTIF_APP_SLACK": r"^Slack$|Slack",
        # Hot = mención/DM/urgente/temas. NO nombres de emisores (el body siempre trae "Nombre: …").
        "KZ_NOTIF_KW_SLACK": (
            r"mentioned you|te mencion|envió un mensaje|sent you a message|"
            r"DM from|direct message|@here|@channel|@everyone|"
            r"urgente|urgent|P0|VPN|RCA|KB|factura|SLA|SICAI|celeridad|"
            r"bloqueo|desbloque|impediment|credencial"
        ),
        # 0 = el agente pica con comentario real; 1 = "voltea" vacío (legacy, engañoso)
        "KZ_NOTIF_SOFT_PING": "0",
        # Si 1, cualquier mensaje Slack genera pending (más ruido)
        "KZ_NOTIF_SLACK_ALL_HOT": "0",
    }
    if FILTERS.is_file():
        for line in FILTERS.read_text(encoding="utf-8", errors="replace").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, _, v = line.partition("=")
            defaults[k.strip()] = v.strip().strip("'").strip('"')
    return defaults


F = load_filters()


def ci_search(hay: str, pattern: str) -> bool:
    if not pattern or not hay:
        return False
    try:
        return re.search(pattern, hay, re.I) is not None
    except re.error:
        return pattern.lower() in hay.lower()


def slack_body_for_match(body: str) -> str:
    """Quita el prefijo 'Nombre Apellido: ' del emisor para no hot-ear por nombre."""
    return re.sub(r"^[^:]{1,80}:\s*", "", body or "", count=1)


def classify(app: str, summary: str, body: str) -> str:
    blob = f"{app} | {summary} | {body}"
    if ci_search(blob, F.get("KZ_NOTIF_BLOCK", "")):
        return "skip"
    # Nunca hot/pending de nuestras propias campanitas (evita bucle tray→CHANGED)
    if ci_search(app, r"^Kz$|^Kz ·|kz-nudge"):
        return "desktop_seen"
    # 2026-07-31: Lalo — mute Phone/SMS/missed-call spam for now
    if ci_search(app, r"Phone|Teléfono|Telephony|Messages|Mensajes|^SMS$|KDE Connect"):
        return "skip"
    if ci_search(blob, r"Missed call|missed call|Sensitive notification"):
        return "skip"
    if ci_search(app, F.get("KZ_NOTIF_APP_SLACK", "Slack")):
        if F.get("KZ_NOTIF_SLACK_ALL_HOT", "0") == "1":
            return "slack_hot"
        # Match en summary + body sin emisor (nombres del canal no bastan solos)
        slack_blob = f"{summary} | {slack_body_for_match(body)}"
        if ci_search(slack_blob, F.get("KZ_NOTIF_KW_SLACK", "mentioned|urgente")):
            return "slack_hot"
        return "slack_seen"
    if ci_search(app, F.get("KZ_NOTIF_APP_IMPORTANT", "")):
        return "important"
    if ci_search(blob, F.get("KZ_NOTIF_KW_IMPORTANT", "")):
        return "important"
    if ci_search(app, F.get("KZ_NOTIF_APP_MAIL", "")) and ci_search(
        blob, F.get("KZ_NOTIF_KW_MAIL", "")
    ):
        return "mail_work"
    return "desktop_seen"


def fp_of(*parts: str) -> str:
    return hashlib.sha256("|".join(parts).encode("utf-8", errors="replace")).hexdigest()[
        :16
    ]


def already_seen(fp: str) -> bool:
    if not SEEN.is_file():
        return False
    text = SEEN.read_text(encoding="utf-8", errors="replace")
    return fp in text


def mark_seen(fp: str, kind: str, app: str) -> None:
    with SEEN.open("a", encoding="utf-8") as f:
        f.write(f"{fp}\t{kind}\t{app}\n")


def now() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def stream_line(kind: str, app: str, summary: str, body: str) -> None:
    NOTIF_DIR.mkdir(parents=True, exist_ok=True)
    line = f"{now()}\t{kind}\t{app}\t{summary}\t{body}".replace("\n", " ")
    with STREAM.open("a", encoding="utf-8") as f:
        f.write(line[:800] + "\n")


def write_pending(kind: str, app: str, summary: str, body: str) -> None:
    NOTIF_DIR.mkdir(parents=True, exist_ok=True)
    s = summary.replace("\n", " ")
    b = body.replace("\n", " ")
    when = now()
    label = f"{kind}: {app} — {s}"[:120]
    PENDING.write_text(
        f"""# Pending — notif Kz (desktop)

- **cuando:** {when}
- **clase:** {kind}
- **app:** {app}
- **título:** {s}
- **texto:** {b}
- **estado:** awaiting_kz_comment

El agente: comentar en chat (voz Kz), tray si cabe, clear:
`~/kz/scripts/kz-notif-watch.sh clear`
""",
        encoding="utf-8",
    )
    PENDING_TS.write_text(when + "\n", encoding="utf-8")
    PENDING_LABELS.write_text(label + "\n", encoding="utf-8")
    with EVENTS.open("a", encoding="utf-8") as f:
        f.write(f"{when} DESKTOP {kind} app={app} title={s}\n")
    changed_line = f"CHANGED: notif:{kind}:{app}:{s[:80]}"
    print(changed_line, flush=True)
    # Wake confiable para el monitor del agente (stdout del daemon se pierde en nohup)
    with CHANGED_LOG.open("a", encoding="utf-8") as f:
        f.write(f"{when}\t{changed_line}\n")
    # Soft-ping "voltea" vacío: OFF por defecto. El agente comenta y luego --say.
    if F.get("KZ_NOTIF_SOFT_PING", "0") == "1":
        nudge = KZ_HOME / "scripts" / "kz-nudge.sh"
        if nudge.is_file():
            subprocess.Popen(
                [str(nudge), "--terminal", "Notif desktop/Slack. Voltea a Grok (Kz)."],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )


def handle_notify(app: str, summary: str, body: str) -> None:
    app, summary, body = app.strip(), summary.strip(), body.strip()
    if not app and not summary:
        return
    kind = classify(app, summary, body)
    fp = fp_of(app, summary, body)
    stream_line(kind, app, summary, body)

    if kind in ("skip", "slack_seen", "desktop_seen"):
        if not already_seen(fp):
            mark_seen(fp, kind, app)
        return
    if already_seen(fp):
        return
    mark_seen(fp, kind, app)
    write_pending(kind, app, summary, body)


def parse_monitor(proc: subprocess.Popen) -> None:
    """Parse dbus-monitor Notify blocks."""
    app = summary = body = None
    string_idx = 0
    in_notify = False

    assert proc.stdout is not None
    for raw in proc.stdout:
        line = raw.rstrip("\n")
        if "member=Notify" in line and "Notifications" in line:
            in_notify = True
            app = summary = body = None
            string_idx = 0
            continue
        if not in_notify:
            continue
        # next method call ends block
        if line.startswith("method ") and "member=Notify" not in line:
            if app is not None:
                handle_notify(app or "", summary or "", body or "")
            in_notify = False
            continue
        m = re.match(r'^\s*string\s+"(.*)"\s*$', line)
        if not m:
            # unquoted empty
            if re.match(r"^\s*string\s+\"\"\s*$", line):
                val = ""
            else:
                # multiline strings rare; skip
                continue
        else:
            val = m.group(1)
            # unescape
            val = val.replace("\\n", " ").replace('\\"', '"')

        # Notify args: 0 app_name, 1 replaces_id is uint, 2 icon, 3 summary, 4 body
        # We only see string lines: app, icon, summary, body (replaces_id is uint32)
        if string_idx == 0:
            app = val
        elif string_idx == 1:
            # icon
            pass
        elif string_idx == 2:
            summary = val
        elif string_idx == 3:
            body = val
            handle_notify(app or "", summary or "", body or "")
            in_notify = False
            app = summary = body = None
            string_idx = 0
            continue
        string_idx += 1


def main() -> int:
    NOTIF_DIR.mkdir(parents=True, exist_ok=True)
    if PIDFILE.is_file():
        try:
            old = int(PIDFILE.read_text().strip())
            os.kill(old, 0)
            print(f"error: desktop notif watch ya corre pid {old}", file=sys.stderr)
            return 1
        except (ValueError, OSError):
            PIDFILE.unlink(missing_ok=True)

    PIDFILE.write_text(str(os.getpid()) + "\n")

    def cleanup(*_a):
        PIDFILE.unlink(missing_ok=True)
        sys.exit(0)

    signal.signal(signal.SIGTERM, cleanup)
    signal.signal(signal.SIGINT, cleanup)

    with EVENTS.open("a", encoding="utf-8") as f:
        f.write(f"{now()} desktop notif watch start pid={os.getpid()}\n")
    print(f"desktop notif watch pid {os.getpid()}", file=sys.stderr)

    proc = subprocess.Popen(
        [
            "dbus-monitor",
            "--session",
            "interface='org.freedesktop.Notifications',member=Notify",
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        bufsize=1,
    )
    try:
        parse_monitor(proc)
    finally:
        proc.terminate()
        PIDFILE.unlink(missing_ok=True)
    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "stop":
        if PIDFILE.is_file():
            try:
                os.kill(int(PIDFILE.read_text().strip()), signal.SIGTERM)
                print("stopped desktop notif watch")
            except (ValueError, OSError) as e:
                print(f"stop: {e}")
                PIDFILE.unlink(missing_ok=True)
        else:
            print("no desktop notif watch")
        raise SystemExit(0)
    raise SystemExit(main())
