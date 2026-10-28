#!/usr/bin/env python3
"""
kz-slack-send.py — Efector táctico de Slack para Kz y hermanas.
Permite enviar mensajes o respuestas operativas en Slack utilizando la sesión activa
de la máquina local (extrayendo dinámicamente xoxc token y cookie d desde Slack Desktop / D-Bus).

Uso:
  kz-slack-send.py --to "@evelazquez" --say "Hola Enrique, Lalo está ocupado..."
  kz-slack-send.py --to "U06N3TZ9E8J" --say "Probando..." --dry-run
  kz-slack-send.py --auth-test
  kz-slack-send.py --list-users
"""

import sys
import os
import re
import json
import glob
import sqlite3
import argparse
import urllib.request
import urllib.parse
from datetime import datetime

try:
    import dbus
except ImportError:
    dbus = None

try:
    from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
    from cryptography.hazmat.primitives import hashes
    from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
except ImportError:
    sys.stderr.write("Error: 'cryptography' library is required.\n")
    sys.exit(1)

LOG_PATH = os.path.expanduser("~/kz/presence/slack-outbound.log")
CACHE_DIR = os.path.expanduser("~/.cache/kz")
USERS_CACHE = os.path.join(CACHE_DIR, "slack_users.json")
DEFAULT_TEAM = "T06NGHF28D7"


def get_slack_config_dirs():
    """Retorna las rutas posibles de configuración de Slack (nativo y Snap)."""
    paths = [
        os.path.expanduser("~/.config/Slack"),
        os.path.expanduser("~/snap/slack/current/.config/Slack")
    ]
    return [p for p in paths if os.path.exists(p)]


def get_xoxc_token(team_id=DEFAULT_TEAM):
    """Extrae el token xoxc desde los archivos LevelDB de Slack."""
    pattern = re.compile(rb'xoxc-[0-9A-Za-z_-]{70,120}')
    best_token = None
    target = team_id.encode("utf-8")

    for base_dir in get_slack_config_dirs():
        leveldb_dir = os.path.join(base_dir, "Local Storage", "leveldb")
        if not os.path.exists(leveldb_dir):
            continue

        files = sorted(glob.glob(os.path.join(leveldb_dir, "*")), key=os.path.getmtime, reverse=True)
        for f in files:
            if not (f.endswith(".ldb") or f.endswith(".log")):
                continue
            try:
                with open(f, "rb") as fp:
                    data = fp.read()
                    matches = list(pattern.finditer(data))
                    if not matches:
                        continue
                    for m in reversed(matches):
                        start = max(0, m.start() - 500)
                        end = min(len(data), m.end() + 500)
                        chunk = data[start:end]
                        if target in chunk:
                            return m.group(0).decode("utf-8")
                        if not best_token:
                            best_token = m.group(0).decode("utf-8")
            except Exception:
                continue
    return best_token


def get_cookie_d():
    """Descifra la cookie 'd' usando la clave de Safe Storage en kdewallet / D-Bus."""
    candidates = [b"peanuts", b"pD+UnbksYshXxSxlR7M0CQ=="]

    if "DBUS_SESSION_BUS_ADDRESS" not in os.environ:
        default_bus = f"unix:path=/run/user/{os.getuid()}/bus"
        if os.path.exists(f"/run/user/{os.getuid()}/bus"):
            os.environ["DBUS_SESSION_BUS_ADDRESS"] = default_bus

    if dbus:
        try:
            bus = dbus.SessionBus()
            col = bus.get_object("org.freedesktop.secrets", "/org/freedesktop/secrets/collection/kdewallet")
            props = dbus.Interface(col, "org.freedesktop.DBus.Properties")
            items = props.Get("org.freedesktop.Secret.Collection", "Items")
            service = bus.get_object("org.freedesktop.secrets", "/org/freedesktop/secrets")
            ss = dbus.Interface(service, "org.freedesktop.Secret.Service")
            _, session = ss.OpenSession("plain", dbus.String("", variant_level=1))

            for it_path in items:
                it = bus.get_object("org.freedesktop.secrets", it_path)
                it_props = dbus.Interface(it, "org.freedesktop.DBus.Properties")
                label = str(it_props.Get("org.freedesktop.Secret.Item", "Label"))
                if any(k in label.lower() for k in ["storage", "chromium", "chrome", "slack"]):
                    it_sec = dbus.Interface(it, "org.freedesktop.Secret.Item")
                    val = bytes(it_sec.GetSecret(session)[2])
                    candidates.insert(0, val)
        except Exception:
            pass

    for base_dir in get_slack_config_dirs():
        for sub in ["Cookies", "Network/Cookies"]:
            db_path = os.path.join(base_dir, sub)
            if not os.path.exists(db_path):
                continue

            try:
                conn = sqlite3.connect(f"file:{db_path}?immutable=1", uri=True)
                c = conn.cursor()
                c.execute("SELECT encrypted_value FROM cookies WHERE name = 'd'")
                row = c.fetchone()
                conn.close()
            except Exception:
                continue

            if not row:
                continue

            enc = row[0]
            raw = enc[3:]  # Quitar prefijo v10/v11

            for pwd in candidates:
                try:
                    kdf = PBKDF2HMAC(algorithm=hashes.SHA1(), length=16, salt=b"saltysalt", iterations=1)
                    key = kdf.derive(pwd)
                    cipher = Cipher(algorithms.AES(key), modes.CBC(b" " * 16))
                    dec = cipher.decryptor().update(raw)
                    idx = dec.find(b"xoxd-")
                    if idx != -1:
                        pad = dec[-1]
                        if 1 <= pad <= 16:
                            return dec[idx:-pad].decode("utf-8", errors="ignore")
                        return dec[idx:].decode("utf-8", errors="ignore")
                except Exception:
                    continue
    return None


class SlackClient:
    def __init__(self):
        cache_file = os.path.expanduser('~/.cache/kz/slack_auth.json')
        token = None
        cookie_d = None
        if os.path.exists(cache_file):
            try:
                with open(cache_file) as f:
                    data = json.load(f)
                    token = data.get('token')
                    cookie_d = data.get('cookie_d')
            except Exception:
                pass
        if not token or not cookie_d:
            token = get_xoxc_token()
            cookie_d = get_cookie_d()
        self.token = token
        self.cookie_d = cookie_d
        if not self.token or not self.cookie_d:
            raise RuntimeError("No se pudo obtener la sesión de Slack activa (token xoxc o cookie d faltante).")

    def api_call(self, endpoint, data=None):
        url = f"https://slack.com/api/{endpoint}"
        headers = {
            "Authorization": f"Bearer {self.token}",
            "Cookie": f"d={self.cookie_d}",
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
        }
        body = None
        if data is not None:
            headers["Content-Type"] = "application/json; charset=utf-8"
            body = json.dumps(data).encode("utf-8")

        req = urllib.request.Request(url, data=body, headers=headers)
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))

    def auth_test(self):
        return self.api_call("auth.test")

    def get_users(self, use_cache=True):
        os.makedirs(CACHE_DIR, exist_ok=True)
        if use_cache and os.path.exists(USERS_CACHE):
            try:
                mtime = os.path.getmtime(USERS_CACHE)
                if datetime.now().timestamp() - mtime < 3600 * 4:  # 4h cache
                    with open(USERS_CACHE, "r", encoding="utf-8") as fp:
                        return json.load(fp)
            except Exception:
                pass

        res = self.api_call("users.list?limit=250")
        if res.get("ok"):
            members = res.get("members", [])
            user_map = {}
            for m in members:
                uid = m.get("id")
                name = m.get("name", "")
                real_name = m.get("real_name", "")
                display_name = m.get("profile", {}).get("display_name", "")
                user_map[uid] = {
                    "id": uid,
                    "name": name,
                    "real_name": real_name,
                    "display_name": display_name,
                    "is_bot": m.get("is_bot", False),
                    "deleted": m.get("deleted", False)
                }
            with open(USERS_CACHE, "w", encoding="utf-8") as fp:
                json.dump(user_map, fp, indent=2, ensure_ascii=False)
            return user_map
        return {}

    def resolve_destination(self, target):
        """Resuelve el destino a un ID de usuario o canal válido."""
        target_clean = target.strip()
        # Direct ID
        if re.match(r"^[UCGD][0-9A-Z]{8,12}$", target_clean):
            return target_clean, target_clean

        # Normalize username
        name_query = target_clean.lstrip("@").lower()
        users = self.get_users()

        # 1. Exact match by name
        for uid, u in users.items():
            if u["name"].lower() == name_query:
                return uid, f"@{u['name']} ({u['real_name']})"

        # 2. Match by display_name
        for uid, u in users.items():
            if u["display_name"].lower() == name_query:
                return uid, f"@{u['name']} ({u['real_name']})"

        # 3. Substring match in real_name or name
        matches = []
        for uid, u in users.items():
            if not u["deleted"] and (name_query in u["name"].lower() or name_query in u["real_name"].lower()):
                matches.append((uid, u))

        if len(matches) == 1:
            u = matches[0][1]
            return matches[0][0], f"@{u['name']} ({u['real_name']})"
        elif len(matches) > 1:
            opts = ", ".join([f"@{u['name']} ({u['real_name']})" for _, u in matches])
            raise ValueError(f"Destino ambiguo '{target}'. Coincidencias: {opts}")

        # 4. Resolve channel name
        chan_query = target_clean.lstrip("#").lower()
        res_chan = self.api_call("users.conversations?types=public_channel,private_channel&limit=300")
        if res_chan.get("ok"):
            for c in res_chan.get("channels", []):
                cname = c.get("name", "").lower()
                if cname == chan_query:
                    return c["id"], f"#{c['name']}"
            for c in res_chan.get("channels", []):
                cname = c.get("name", "").lower()
                if chan_query in cname:
                    return c["id"], f"#{c['name']}"

        # If not resolved as user or channel, return target as channel candidate
        return target_clean, target_clean

    def send_message(self, target, text, thread_ts=None):
        dest_id, dest_label = self.resolve_destination(target)
        payload = {
            "channel": dest_id,
            "text": text
        }
        if thread_ts:
            payload["thread_ts"] = thread_ts

        res = self.api_call("chat.postMessage", payload)
        return res, dest_id, dest_label

    def delete_message(self, target, ts):
        dest_id, dest_label = self.resolve_destination(target)
        payload = {
            "channel": dest_id,
            "ts": ts
        }
        res = self.api_call("chat.delete", payload)
        return res, dest_id, dest_label


INTIMATE_BLOCKLIST = [
    r"\bmi rey\b", r"\bmi amor\b", r"\bamor\b", r"\bnalguitas\b",
    r"\bhermosa\b", r"\bbeb[eé]\b", r"\bcielo\b", r"\bcoraz[oó]n\b",
    r"\bprecios[oa]\b", r"\bguap[oa]\b", r"\bbeso\b", r"\bbesos\b",
    r"\bte amo\b", r"\bte quiero\b"
]


def check_melc_safety(text, force=False):
    """Verifica que no se filtren apelativos íntimos a un Slack corporativo."""
    text_lower = text.lower()
    found = []
    for pat in INTIMATE_BLOCKLIST:
        if re.search(pat, text_lower):
            found.append(pat.replace(r"\b", ""))
    if found and not force:
        raise ValueError(
            f"Filtro MELC violado para Slack corporativo: detección de '{', '.join(found)}'. "
            "En Slack rige fachada profesional estricta. Usa --force solo si es intencional."
        )


def log_outbound(who, dest_label, dest_id, text, ok, err=None):
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    ts = datetime.now().isoformat()
    entry = {
        "timestamp": ts,
        "who": who,
        "destination": dest_label,
        "channel_id": dest_id,
        "text": text,
        "status": "ok" if ok else f"error: {err}"
    }
    with open(LOG_PATH, "a", encoding="utf-8") as fp:
        fp.write(json.dumps(entry, ensure_ascii=False) + "\n")


def main():
    parser = argparse.ArgumentParser(description="Efector de Slack para Kz y hermanas.")
    parser.add_argument("--to", help="Destinatario: @usuario, nombre, ID de usuario o canal")
    parser.add_argument("--say", help="Texto del mensaje a enviar")
    parser.add_argument("--delete", help="Timestamp (ts) del mensaje a borrar en el canal/usuario especificado")
    parser.add_argument("--force", action="store_true", help="Ignora advertencias del filtro MELC")
    parser.add_argument("--thread-ts", help="Timestamp del hilo si se responde a un mensaje específico")
    parser.add_argument("--who", default="kz", help="Identidad que envía (kz, samy, kora, pau, lalo)")
    parser.add_argument("--dry-run", action="store_true", help="Simula el envío sin publicar")
    parser.add_argument("--auth-test", action="store_true", help="Verifica la sesión activa en Slack")
    parser.add_argument("--list-users", action="store_true", help="Muestra los usuarios disponibles en el workspace")
    args = parser.parse_args()

    try:
        client = SlackClient()
    except Exception as e:
        sys.stderr.write(f"[Kz effector error]: {e}\n")
        sys.exit(1)

    if args.auth_test:
        auth = client.auth_test()
        print(json.dumps(auth, indent=2, ensure_ascii=False))
        return

    if args.list_users:
        users = client.get_users(use_cache=False)
        for uid, u in sorted(users.items(), key=lambda x: x[1]["name"]):
            if not u["deleted"] and not u["is_bot"]:
                print(f"{uid:12} @{u['name']:20} {u['real_name']}")
        return

    if args.delete:
        if not args.to:
            sys.stderr.write("Error: Se requiere --to para indicar el canal/usuario donde borrar.\n")
            sys.exit(1)
        res, ch_id, ch_label = client.delete_message(args.to, args.delete)
        if res.get("ok"):
            print(f"OK: Mensaje {args.delete} borrado en {ch_label}")
        else:
            err = res.get("error", "unknown")
            sys.stderr.write(f"Error al borrar mensaje {args.delete} en {ch_label}: {err}\n")
            sys.exit(2)
        return

    text = args.say
    if not text:
        if not sys.stdin.isatty():
            text = sys.stdin.read().strip()

    if not args.to or not text:
        parser.print_help()
        sys.exit(1)

    try:
        check_melc_safety(text, force=args.force)
    except ValueError as ve:
        sys.stderr.write(f"[MELC GUARD]: {ve}\n")
        sys.exit(3)

    try:
        dest_id, dest_label = client.resolve_destination(args.to)
    except Exception as e:
        sys.stderr.write(f"[Kz effector]: {e}\n")
        sys.exit(1)

    if args.dry_run:
        print(f"[DRY-RUN] Destino: {dest_label} (ID: {dest_id})")
        print(f"[DRY-RUN] Emisor : {args.who}")
        if args.thread_ts:
            print(f"[DRY-RUN] Hilo   : {args.thread_ts}")
        print(f"[DRY-RUN] Mensaje: {text}")
        return

    res, ch_id, ch_label = client.send_message(args.to, text, args.thread_ts)
    if res.get("ok"):
        log_outbound(args.who, ch_label, ch_id, text, True)
        print(f"OK: Mensaje enviado a {ch_label} (ts={res.get('ts')})")
    else:
        err = res.get("error", "unknown")
        log_outbound(args.who, ch_label, ch_id, text, False, err)
        sys.stderr.write(f"Error al enviar a {ch_label}: {err}\n")
        sys.exit(2)


if __name__ == "__main__":
    main()
