#!/usr/bin/env bash
# kz-sync-tablero-rca.sh — Sincroniza el tablero RCA de SAS hacia el servidor privado
set -euo pipefail

RCA_SRC="/home/lalo/Workspace/sas-legacy-migration/rca"
REMOTE_HOST="69.57.161.104"
REMOTE_USER="moia_ops"
REMOTE_DEST="/home/moia_ops/rca-web/html"
URL="https://protein-diversity-emphasis-silicon.trycloudflare.com"

echo "=== Sincronizando Tablero RCA a ${REMOTE_HOST} ==="

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# 1. Copiar activos estáticos
cp "${RCA_SRC}/tablero-rca.html" "${TMP_DIR}/index.html"
cp "${RCA_SRC}/tablero-rca.html" "${TMP_DIR}/tablero-rca.html"
cp "${RCA_SRC}/mapa-tickets-rca.pdf" "${TMP_DIR}/"
cp "${RCA_SRC}/CUADRO_RCA.md" "${TMP_DIR}/"

# 2. Renderizar Cuadro RCA a HTML
python3 -c "
import markdown
with open('${RCA_SRC}/CUADRO_RCA.md', 'r', encoding='utf-8') as f:
    text = f.read()
html_body = markdown.markdown(text, extensions=['tables', 'fenced_code'])
full_html = '''<!doctype html>
<html lang=\"es\">
<head>
<meta charset=\"utf-8\">
<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">
<title>Cuadro General RCA - SECON</title>
<style>
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; max-width: 1200px; margin: 0 auto; padding: 20px; background: #fafafa; color: #222; }
table { border-collapse: collapse; width: 100%; margin: 20px 0; background: #fff; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
th, td { border: 1px solid #ddd; padding: 8px 12px; text-align: left; font-size: 14px; }
th { background: #f0f4f8; font-weight: 600; }
tr:nth-child(even) { background: #f9fbfd; }
code { background: #eee; padding: 2px 5px; border-radius: 3px; font-family: monospace; font-size: 13px; }
h1, h2, h3 { color: #1a365d; }
.nav { margin-bottom: 20px; padding: 10px; background: #fff; border-radius: 5px; box-shadow: 0 1px 2px rgba(0,0,0,0.05); }
.nav a { margin-right: 15px; color: #2b6cb0; text-decoration: none; font-weight: 600; }
</style>
</head>
<body>
<div class=\"nav\">
  <a href=\"index.html\">← Volver al Tablero RCA</a>
  <a href=\"mapa-tickets-rca.pdf\" target=\"_blank\">Ver Mapa de Tickets (PDF)</a>
</div>
''' + html_body + '''
</body>
</html>'''
with open('${TMP_DIR}/cuadro-rca.html', 'w', encoding='utf-8') as f:
    f.write(full_html)
"

chmod 755 "$TMP_DIR"
chmod 644 "$TMP_DIR"/*

# 3. Transferir al servidor
tar -cz -C "$TMP_DIR" . | ssh "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p ${REMOTE_DEST} && tar -xz -C ${REMOTE_DEST} && chmod 755 ${REMOTE_DEST} && chmod 644 ${REMOTE_DEST}/*"

# 4. Comprobación de salud
echo "Verificando endpoint en vivo..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u 'cognitio:SeconRca2026!' "${URL}/")

if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ Sincronización exitosa. Tablero disponible en:"
  echo "👉 ${URL}"
else
  echo "⚠️ Advertencia: El endpoint retornó código HTTP ${HTTP_CODE}"
fi
