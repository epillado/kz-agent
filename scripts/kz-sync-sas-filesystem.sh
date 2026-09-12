#!/usr/bin/env bash
# kz-sync-sas-filesystem.sh — Sincronizador de filesystem SAS legado a disco externo
# Excluye ent2t (3.3 TB) y virtual (756 GB) para ajustar dentro de 2.2 TB disponibles.
#
# Uso:
#   ~/kz/scripts/kz-sync-sas-filesystem.sh start   # Inicia en background
#   ~/kz/scripts/kz-sync-sas-filesystem.sh status  # Muestra avance, velocidad y logs
#   ~/kz/scripts/kz-sync-sas-filesystem.sh stop    # Detiene el proceso limpiamente
#   ~/kz/scripts/kz-sync-sas-filesystem.sh run     # Ejecuta en primer plano

set -euo pipefail

DEST_DIR="/run/media/lalo/Backups/sas-standalone-mirror"
LOG_FILE="${DEST_DIR}/sync.log"
PID_FILE="/tmp/kz-sync-sas.pid"
ASKPASS_FILE="/tmp/askpass-sas-$$.sh"

ACTION="${1:-status}"

_cleanup() {
  rm -f "${ASKPASS_FILE}" 2>/dev/null || true
}
trap _cleanup EXIT

_ensure_mount() {
  if ! mountpoint -q /run/media/lalo/Backups; then
    echo "ERROR: /run/media/lalo/Backups no está montado." >&2
    exit 1
  fi
  mkdir -p "${DEST_DIR}"
}

_create_askpass() {
  cat << 'EOF' > "${ASKPASS_FILE}"
#!/bin/sh
echo "UX4jdNp5"
EOF
  chmod 700 "${ASKPASS_FILE}"
}

_do_rsync() {
  _ensure_mount
  _create_askpass
  
  export SSH_ASKPASS_REQUIRE=force
  export SSH_ASKPASS="${ASKPASS_FILE}"
  
  _echo_log() {
    echo "[$(date -Iseconds)] $1" | tee -a "${LOG_FILE}"
  }
  
  _echo_log "Iniciando rsync desde wildfly@10.100.11.195..."
  
  rsync -avz --stats \
    --exclude="archivodigital/ent2t/" \
    --exclude="archivodigital/virtual/" \
    --include="*/" \
    --include="*.xml" \
    --include="*.pdf" \
    --exclude="*" \
    --prune-empty-dirs \
    -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR" \
    wildfly@10.100.11.195:/u01/usuarios/sasProdFinal/wildfly-9.0.2.Final/standalone/ \
    "${DEST_DIR}/" >> "${LOG_FILE}" 2>&1
}

case "${ACTION}" in
  start)
    _ensure_mount
    if [[ -f "${PID_FILE}" ]] && kill -0 "$(cat "${PID_FILE}")" 2>/dev/null; then
      echo "El proceso de sincronización ya está corriendo (PID: $(cat "${PID_FILE}"))."
      exit 0
    fi
    echo "Iniciando sincronización desacoplada (setsid)..."
    setsid -f "$0" run >/dev/null 2>&1
    sleep 2
    if [[ -f "${PID_FILE}" ]] && kill -0 "$(cat "${PID_FILE}")" 2>/dev/null; then
      echo "Sincronización iniciada con PID $(cat "${PID_FILE}")."
    else
      echo "Sincronización lanzada en background."
    fi
    echo "Log: ${LOG_FILE}"
    ;;

  run)
    echo $$ > "${PID_FILE}"
    _do_rsync
    rm -f "${PID_FILE}" 2>/dev/null || true
    echo "[$(date -Iseconds)] Rsync finalizado exitosamente." >> "${LOG_FILE}"
    ;;

  stop)
    if [[ -f "${PID_FILE}" ]]; then
      PID="$(cat "${PID_FILE}")"
      if kill -0 "${PID}" 2>/dev/null; then
        echo "Deteniendo proceso de sincronización (PID: ${PID})..."
        kill "${PID}" 2>/dev/null || true
        # Matar también hijos de rsync/ssh
        pkill -P "${PID}" 2>/dev/null || true
        sleep 1
        echo "Proceso detenido."
      else
        echo "PID file huérfano. Limpiando."
      fi
      rm -f "${PID_FILE}"
    else
      echo "No hay proceso de sincronización registrado en ${PID_FILE}."
    fi
    ;;

  status)
    _ensure_mount
    echo "=== Estado de sincronización SAS ==="
    if [[ -f "${PID_FILE}" ]] && kill -0 "$(cat "${PID_FILE}")" 2>/dev/null; then
      echo "ESTADO: EN EJECUCIÓN (PID: $(cat "${PID_FILE}"))"
    else
      echo "ESTADO: DETENIDO / INACTIVO"
    fi
    echo ""
    echo "=== Espacio en disco externo ==="
    df -h /run/media/lalo/Backups
    echo ""
    echo "=== Tamaño descargado hasta ahora en destino ==="
    du -sh "${DEST_DIR}" 2>/dev/null || echo "0 B"
    echo ""
    echo "=== Últimas 15 líneas del log (${LOG_FILE}) ==="
    if [[ -f "${LOG_FILE}" ]]; then
      tail -n 15 "${LOG_FILE}"
    else
      echo "(Sin archivo de log aún)"
    fi
    ;;

  *)
    echo "Uso: $0 {start|status|stop|run}"
    exit 1
    ;;
esac
