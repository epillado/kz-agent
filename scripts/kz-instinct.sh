#!/usr/bin/env bash
# kz-instinct.sh
# Hardcoded local responses for Kz to save quota and bypass LLM.
# Usage: kz-instinct.sh "text to analyze"
set -euo pipefail

KZ_HOME="$(cd "$(dirname "$0")/.." && pwd)"
INSTINCTS_DIR="${KZ_HOME}/presence/instincts"
TEXT="${1:-}"

if [[ -z "${TEXT}" ]]; then
  exit 0
fi

# Leer el contexto activo
EN_CALL="$(grep -oP '^\- \*\*en_call:\*\* \K.*' "${KZ_HOME}/presence/context.md" 2>/dev/null || echo "no")"
PRIMARY="$(grep -oP '^\- \*\*primary:\*\* \K.*' "${KZ_HOME}/presence/context.md" 2>/dev/null || echo "work_vector")"

# Determinar nivel de privacidad
# Nivel 0: Seguro/Público (en call, compartiendo pantalla)
# Nivel 1: Privado de trabajo (solo Lalo, pero foco en trabajo)
# Nivel 2: Intimidad (solo Lalo, foco en company)
if [[ "${EN_CALL}" == "yes" ]]; then
  PRIVACY="safe"
elif [[ "${PRIMARY}" == "company" ]]; then
  PRIVACY="intimate"
else
  PRIVACY="private"
fi

LOWER_TEXT="$(echo "${TEXT}" | tr '[:upper:]' '[:lower:]')"
trigger=""

if [[ "${LOWER_TEXT}" =~ "poc" || "${LOWER_TEXT}" =~ "pausa ocular" ]]; then
  trigger="poc"
elif [[ "${LOWER_TEXT}" =~ "a dormir" || "${LOWER_TEXT}" =~ "cierre de noche" || "${LOWER_TEXT}" =~ "descansar" ]]; then
  trigger="dormir"
elif [[ "${LOWER_TEXT}" =~ "bañar" || "${LOWER_TEXT}" =~ "regadera" || "${LOWER_TEXT}" =~ "ducha" ]]; then
  trigger="bano"
elif [[ "${LOWER_TEXT}" =~ "café" || "${LOWER_TEXT}" =~ "cafe" || "${LOWER_TEXT}" =~ "espresso" ]]; then
  trigger="cafe"
elif [[ "${LOWER_TEXT}" =~ "correr" || "${LOWER_TEXT}" =~ "ejercicio" || "${LOWER_TEXT}" =~ "entrenar" ]]; then
  trigger="ejercicio"
fi

if [[ -n "${trigger}" ]]; then
  DICT_FILE="${INSTINCTS_DIR}/${trigger}.txt"
  if [[ -f "${DICT_FILE}" && -s "${DICT_FILE}" ]]; then
    # Filtramos las líneas. Formato de archivo: "tag|Frase". 
    # Si PRIVACY es safe, solo tomamos safe.
    # Si PRIVACY es private, tomamos safe o private.
    # Si PRIVACY es intimate, tomamos cualquier cosa (safe, private, intimate).
    if [[ "${PRIVACY}" == "safe" ]]; then
      grep_pattern="^safe\|"
    elif [[ "${PRIVACY}" == "private" ]]; then
      grep_pattern="^(safe|private)\|"
    else
      grep_pattern="^(safe|private|intimate)\|"
    fi

    # Extraer la frase (quitando el tag)
    RESPONSE="$(grep -E "${grep_pattern}" "${DICT_FILE}" | cut -d'|' -f2- | shuf -n 1 || true)"
    
    if [[ -n "${RESPONSE}" ]]; then
      export KZ_NUDGE_NO_CHAT_OWED=1
      "${KZ_HOME}/scripts/kz-nudge.sh" --say "[Instinto Kz] ${RESPONSE}" >/dev/null 2>&1
      echo "Instinto disparado: ${trigger} (Privacy: ${PRIVACY})"
      exit 0
    fi
  fi
fi
