#!/usr/bin/env bash
# ==============================================================================
# kz-bitbucket.sh — Efector de Bitbucket para Kz (Aprobación, Merge, Comentarios)
# ==============================================================================
set -euo pipefail

BB_EMAIL="${BB_EMAIL:-eduardo.pillado@redts.lat}"
BB_API_TOKEN="${BB_API_TOKEN:-}"

if [[ -z "$BB_API_TOKEN" ]]; then
    # Intentar leer de .env en sas-backend-core o playbook
    if [[ -f "${HOME}/Workspace/sas-backend-core/.env" ]]; then
        BB_API_TOKEN="$(grep -E '^BB_API_TOKEN=' "${HOME}/Workspace/sas-backend-core/.env" | cut -d= -f2- | tr -d '\"'\')"
    fi
fi

if [[ -z "$BB_API_TOKEN" ]]; then
    echo "❌ Error: BB_API_TOKEN no está definido en el entorno ni en .env." >&2
    exit 1
fi

AUTH="${BB_EMAIL}:${BB_API_TOKEN}"
BASE_URL="https://api.bitbucket.org/2.0/repositories"

ACTION="${1:-}"
REPO="${2:-}"
PR_ID="${3:-}"

# Normalizar repo slug: si no contiene '/', asumir workspace 'redts'
if [[ "$REPO" != *"/"* && -n "$REPO" ]]; then
    REPO="redts/${REPO}"
fi

usage() {
    echo "Uso: $0 <info|approve|merge|comment|unapprove|create|decline> <repo_slug> <pr_id_or_src_branch> [args...]"
    echo ""
    echo "Ejemplos:"
    echo "  $0 info sas-backend-core 431"
    echo "  $0 approve sas-backend-core 431"
    echo "  $0 comment sas-backend-core 431 \"Observaciones técnicas...\""
    echo "  $0 merge sas-backend-core 431 \"Merge pull request #431\""
    echo "  $0 create sas-backend-core fix/mi-rama develop \"Título del PR\" \"Descripción\""
    exit 1
}

[[ -n "$ACTION" && -n "$REPO" && -n "$PR_ID" ]] || usage

case "$ACTION" in
    info)
        curl -s -f -u "$AUTH" "${BASE_URL}/${REPO}/pullrequests/${PR_ID}" | python3 -c '
import sys, json
d = json.load(sys.stdin)
pid = d.get("id")
title = d.get("title")
state = d.get("state")
author = d.get("author", {}).get("display_name")
src = d.get("source", {}).get("branch", {}).get("name")
commit = d.get("source", {}).get("commit", {}).get("hash", "")[:7]
dst = d.get("destination", {}).get("branch", {}).get("name")
approvers = [p.get("user",{}).get("display_name") for p in d.get("participants",[]) if p.get("approved")]
print(f"PR #{pid}: {title}")
print(f"Estado:      {state}")
print(f"Autor:       {author}")
print(f"Origen:      {src} ({commit})")
print(f"Destino:     {dst}")
print(f"Aprobado por: {approvers}")
'
        ;;
    approve)
        echo "Aprobando PR #${PR_ID} en ${REPO}..."
        RESP="$(curl -s -f -X POST -u "$AUTH" "${BASE_URL}/${REPO}/pullrequests/${PR_ID}/approve")"
        python3 -c 'import sys, json; d = json.load(sys.stdin); print("✅ Aprobado:", d.get("approved"), "por", d.get("user",{}).get("display_name"))' <<< "$RESP"
        ;;
    unapprove)
        echo "Retirando aprobación de PR #${PR_ID} en ${REPO}..."
        curl -s -f -X DELETE -u "$AUTH" "${BASE_URL}/${REPO}/pullrequests/${PR_ID}/approve"
        echo "✅ Aprobación retirada."
        ;;
    comment)
        COMMENT="${4:-}"
        [[ -n "$COMMENT" ]] || { echo "Error: se requiere el texto del comentario." >&2; exit 1; }
        echo "Publicando comentario en PR #${PR_ID}..."
        PAYLOAD="$(python3 -c 'import sys, json; print(json.dumps({"content": {"raw": sys.argv[1]}}))' "$COMMENT")"
        RESP="$(curl -s -f -X POST -u "$AUTH" -H "Content-Type: application/json" -d "$PAYLOAD" "${BASE_URL}/${REPO}/pullrequests/${PR_ID}/comments")"
        echo "✅ Comentario publicado exitosamente."
        ;;
    create)
        SRC="${PR_ID}" # en create, el tercer argumento es la rama origen
        DST="${4:-develop}"
        TITLE="${5:-Merge ${SRC} into ${DST}}"
        DESC="${6:-}"
        echo "Creando PR de ${SRC} hacia ${DST} en ${REPO}..."
        PAYLOAD="$(python3 -c 'import sys, json; print(json.dumps({"title": sys.argv[3], "description": sys.argv[4], "source": {"branch": {"name": sys.argv[1]}}, "destination": {"branch": {"name": sys.argv[2]}}, "close_source_branch": False}))' "$SRC" "$DST" "$TITLE" "$DESC")"
        RESP="$(curl -s -f -X POST -u "$AUTH" -H "Content-Type: application/json" -d "$PAYLOAD" "${BASE_URL}/${REPO}/pullrequests")"
        python3 -c 'import sys, json; d = json.load(sys.stdin); print("✅ PR Creado con éxito. ID:", d.get("id"), "URL:", d.get("links",{}).get("html",{}).get("href"))' <<< "$RESP"
        ;;
    merge)
        MSG="${4:-Merge pull request #${PR_ID} into develop}"
        STRATEGY="${5:-merge_commit}"
        echo "Ejecutando merge de PR #${PR_ID} en ${REPO}..."
        PAYLOAD="$(python3 -c 'import sys, json; print(json.dumps({"message": sys.argv[1], "close_source_branch": False, "merge_strategy": sys.argv[2]}))' "$MSG" "$STRATEGY")"
        RESP="$(curl -s -f -X POST -u "$AUTH" -H "Content-Type: application/json" -d "$PAYLOAD" "${BASE_URL}/${REPO}/pullrequests/${PR_ID}/merge")"
        python3 -c 'import sys, json; d = json.load(sys.stdin); print("✅ Fusionado con éxito. Estado:", d.get("state"), "Commit destino:", d.get("merge_commit",{}).get("hash", "")[:7])' <<< "$RESP"
        ;;
    decline)
        echo "Declinando PR #${PR_ID} en ${REPO}..."
        RESP="$(curl -s -f -X POST -u "$AUTH" "${BASE_URL}/${REPO}/pullrequests/${PR_ID}/decline")"
        python3 -c 'import sys, json; d = json.load(sys.stdin); print("✅ Declinado con éxito. Estado:", d.get("state"))' <<< "$RESP"
        ;;
    *)
        usage
        ;;
esac
