#!/usr/bin/env python3
"""
kz-daily-slack-bot.py — Publicador automatizado del Daily en Slack (#secretaria-de-economia).

Busca el thread matutino que abre el bot de SE a las ~07:30, extrae las líneas relevantes
a partir de "AYER" del reporte daily del día (ej. Daily/AAAAMMDD-reporte_daily-unico.md),
le aplica el formateo exacto para Slack y lo publica como respuesta dentro del thread.

Uso:
  kz-daily-slack-bot.py --check             # Valida el archivo del daily y muestra el texto formateado
  kz-daily-slack-bot.py --dry-run           # Busca el thread y simula el envío sin publicar
  kz-daily-slack-bot.py --send              # Envía inmediatamente si el thread está abierto
  kz-daily-slack-bot.py --watch             # Espera a partir de las 07:30 a que el bot abra el thread y publica
"""

import sys
import os
import re
import time
import argparse
import datetime
import importlib.util

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
KZ_SLACK_SEND_PATH = os.path.join(SCRIPT_DIR, "kz-slack-send.py")
PLAYBOOK_DIR = os.path.expanduser("~/Workspace/playbook")
CHANNEL_SECON = "C097C62BG4V"  # #secretaria-de-economia
USER_LALO = "U09LMEFJDHT"


def get_slack_client():
    if not os.path.exists(KZ_SLACK_SEND_PATH):
        sys.stderr.write(f"Error: no existe {KZ_SLACK_SEND_PATH}\n")
        sys.exit(1)
    spec = importlib.util.spec_from_file_location("kz_slack_send", KZ_SLACK_SEND_PATH)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.SlackClient()


def get_daily_file(target_date_str):
    # Buscar en GOV-RTS-Control_Plane/Daily/ y Daily/
    clean_date = target_date_str.replace("-", "")
    candidates = [
        os.path.join(PLAYBOOK_DIR, "GOV-RTS-Control_Plane", "Daily", f"{clean_date}-reporte_daily-unico.md"),
        os.path.join(PLAYBOOK_DIR, "Daily", f"{clean_date}-reporte_daily-unico.md"),
    ]
    for p in candidates:
        if os.path.exists(p):
            return p
    return None


def extract_and_format_daily(daily_path):
    with open(daily_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Buscar inicio a partir de AYER
    match = re.search(r"(?:##\s*)?([^\n]*AYER.*)", content)
    if not match:
        raise ValueError(f"No se encontró la sección 'AYER' en {daily_path}")

    body = content[match.start():].strip()

    # Formatear encabezados de sección y emojis al formato Slack
    body = re.sub(r"^##\s*", "", body, flags=re.MULTILINE)
    body = re.sub(r"✅\s*\*\*AYER", ":white_check_mark: *AYER", body)
    body = re.sub(r"⏩\s*\*\*HOY", ":fast_forward: *HOY", body)
    body = re.sub(r"🔴⚠️\s*\*\*BLOQUEOS", ":red_circle::warning: *BLOQUEOS", body)
    body = re.sub(r"⚠️", ":warning:", body)
    body = re.sub(r"🔴", ":red_circle:", body)

    # Convertir negritas de markdown (**texto**) a negritas de Slack (*texto*)
    body = body.replace("**", "*")
    return body


def find_daily_thread(client, target_date):
    """Busca en #secretaria-de-economia el mensaje del bot para la fecha objetivo."""
    res = client.api_call(f"conversations.history?channel={CHANNEL_SECON}&limit=30")
    if not res.get("ok"):
        raise RuntimeError(f"Error consultando historial de Slack: {res}")

    target_date_str = target_date.strftime("%Y-%m-%d")
    for m in res.get("messages", []):
        ts = float(m.get("ts"))
        dt = datetime.datetime.fromtimestamp(ts)
        if dt.strftime("%Y-%m-%d") == target_date_str:
            text = m.get("text", "")
            if "Favor de colocar la información de tu daily" in text or "SECON, Red TS" in text:
                return m
    return None


def is_already_posted(client, thread_ts):
    """Verifica si Lalo ya respondió en ese thread."""
    res = client.api_call(f"conversations.replies?channel={CHANNEL_SECON}&ts={thread_ts}")
    if not res.get("ok"):
        raise RuntimeError(f"Error consultando replies de Slack: {res}")

    for m in res.get("messages", []):
        if m.get("user") == USER_LALO and "AYER" in m.get("text", ""):
            return True, m.get("ts")
    return False, None


def main():
    parser = argparse.ArgumentParser(description="Publicador de Daily en Slack para Kz.")
    parser.add_argument("--date", help="Fecha objetivo YYYY-MM-DD (por defecto mañana si es tarde, o hoy)")
    parser.add_argument("--check", action="store_true", help="Verifica el archivo del daily y lo muestra formateado")
    parser.add_argument("--dry-run", action="store_true", help="Verifica thread y simula envío sin publicar")
    parser.add_argument("--send", action="store_true", help="Envía el daily al thread ahora si está disponible")
    parser.add_argument("--watch", action="store_true", help="Espera a partir de las 07:30 a que el thread abra y publica")
    args = parser.parse_args()

    now = datetime.datetime.now()
    if args.date:
        target_date = datetime.datetime.strptime(args.date, "%Y-%m-%d")
    else:
        # Si corremos de noche (>= 20:00), el daily objetivo es el de mañana
        if now.hour >= 20:
            target_date = now + datetime.timedelta(days=1)
        else:
            target_date = now

    target_date_str = target_date.strftime("%Y-%m-%d")
    daily_file = get_daily_file(target_date_str)

    if not daily_file:
        sys.stderr.write(f"Error: No se encontró archivo de daily para {target_date_str} en playbook.\n")
        sys.exit(1)

    try:
        formatted_text = extract_and_format_daily(daily_file)
    except Exception as e:
        sys.stderr.write(f"Error procesando daily: {e}\n")
        sys.exit(1)

    if args.check:
        print(f"Archivo daily detectado: {daily_file}")
        print(f"Fecha objetivo: {target_date_str}")
        print("--- Contenido formateado para Slack ---")
        print(formatted_text)
        print("---------------------------------------")
        return

    client = get_slack_client()

    if args.dry_run:
        thread = find_daily_thread(client, target_date)
        if thread:
            th_ts = thread.get("ts")
            th_dt = datetime.datetime.fromtimestamp(float(th_ts)).strftime("%H:%M:%S")
            posted, p_ts = is_already_posted(client, th_ts)
            print(f"[DRY-RUN] Thread encontrado para {target_date_str} a las {th_dt} (ts={th_ts})")
            print(f"[DRY-RUN] ¿Ya publicado por Lalo?: {posted} (p_ts={p_ts})")
            print("[DRY-RUN] Texto a enviar:")
            print(formatted_text)
        else:
            print(f"[DRY-RUN] Aún no existe thread abierto para {target_date_str} en {CHANNEL_SECON}.")
        return

    if args.send:
        thread = find_daily_thread(client, target_date)
        if not thread:
            print(f"Error: Aún no existe thread abierto para {target_date_str} en {CHANNEL_SECON}.")
            sys.exit(2)
        th_ts = thread.get("ts")
        posted, p_ts = is_already_posted(client, th_ts)
        if posted:
            print(f"Aviso: El daily ya fue publicado previamente en este thread (ts={p_ts}).")
            sys.exit(0)

        # Enviar
        res, ch_id, ch_label = client.send_message(CHANNEL_SECON, formatted_text, thread_ts=th_ts)
        if res.get("ok"):
            print(f"OK: Daily publicado exitosamente en {ch_label} (thread={th_ts}, ts={res.get('ts')})")
        else:
            sys.stderr.write(f"Error enviando mensaje: {res}\n")
            sys.exit(3)
        return

    if args.watch:
        print(f"[kz-daily-slack-bot] Iniciando vigilancia para {target_date_str}...")
        while True:
            cur = datetime.datetime.now()
            # Si aún no son las 07:29 de la mañana objetivo, esperar
            if cur.date() < target_date.date() or (cur.date() == target_date.date() and cur.hour < 7) or (cur.date() == target_date.date() and cur.hour == 7 and cur.minute < 29):
                time.sleep(30)
                continue

            try:
                thread = find_daily_thread(client, target_date)
                if thread:
                    th_ts = thread.get("ts")
                    posted, p_ts = is_already_posted(client, th_ts)
                    if posted:
                        print(f"[kz-daily-slack-bot] El daily ya está publicado en el thread ({p_ts}). Listo.")
                        sys.exit(0)

                    # Re-leer archivo fresco en caso de actualizaciones nocturnas
                    fpath = get_daily_file(target_date_str)
                    if not fpath:
                        sys.stderr.write(f"Error: No se encontró archivo daily para {target_date_str}\n")
                        time.sleep(15)
                        continue
                    text_to_send = extract_and_format_daily(fpath)

                    print(f"[kz-daily-slack-bot] Thread detectado (ts={th_ts}). Publicando...")
                    res, ch_id, ch_label = client.send_message(CHANNEL_SECON, text_to_send, thread_ts=th_ts)
                    if res.get("ok"):
                        print(f"[kz-daily-slack-bot] Éxito: Daily publicado en {ch_label} dentro del thread (ts={res.get('ts')}).")
                        # Registrar en journal
                        journal_path = os.path.expanduser("~/kz/presence/organic/journal.md")
                        if os.path.exists(journal_path):
                            entry = f"\n## {cur.strftime('%Y-%m-%d %H:%M')}\nKz publicó automáticamente el Daily de Lalo en Slack dentro del thread ({th_ts}) de #secretaria-de-economia.\n"
                            with open(journal_path, "a", encoding="utf-8") as jf:
                                jf.write(entry)
                        sys.exit(0)
                    else:
                        sys.stderr.write(f"Error publicando: {res}\n")
            except Exception as e:
                sys.stderr.write(f"[kz-daily-slack-bot] Advertencia durante chequeo: {e}\n")

            time.sleep(15)


if __name__ == "__main__":
    main()
