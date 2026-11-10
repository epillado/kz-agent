#!/usr/bin/env bash
# kz-audio-record.sh — Grabadora local de audio de reuniones (ambas vías: sistema + micrófono)
# Diseñado por Kz para capturas operativas y minutas sin depender de permisos externos.
#
# Uso:
#   kz-audio-record.sh start [etiqueta]    # Inicia la grabación en background
#   kz-audio-record.sh stop                # Detiene la grabación limpiamente
#   kz-audio-record.sh status              # Consulta el estado actual
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KZ_HOME="$(cd "${SCRIPT_DIR}/.." && pwd)"
PIDFILE="${KZ_HOME}/presence/audio-record.pid"
METAFILE="${KZ_HOME}/presence/audio-record.meta"

# Directorio de salida: Insumos de Playbook si existe, o local en presence
if [[ -d "${HOME}/Workspace/playbook/Insumos" ]]; then
  DEST_DIR="${HOME}/Workspace/playbook/Insumos/grabaciones"
else
  DEST_DIR="${KZ_HOME}/presence/recordings"
fi
mkdir -p "${DEST_DIR}"

cmd="${1:-status}"

case "${cmd}" in
  start)
    if [[ -f "${PIDFILE}" ]]; then
      pid="$(cat "${PIDFILE}" 2>/dev/null || true)"
      if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
        echo "Aviso: Ya hay una grabación en curso (PID ${pid}). Usa '$0 stop' primero."
        exit 0
      fi
      rm -f "${PIDFILE}"
    fi

    etiqueta="${2:-reunion}"
    # Sanitizar etiqueta
    etiqueta="$(echo "${etiqueta}" | tr ' /:.' '_')"
    ts="$(date '+%Y%m%d-%H%M%S')"
    outfile="${DEST_DIR}/${ts}_${etiqueta}.mp3"
    logfile="${KZ_HOME}/presence/audio-record.log"

    # Detectar dispositivos por defecto de Pulse/PipeWire
    sink="$(pactl get-default-sink 2>/dev/null || echo "")"
    source="$(pactl get-default-source 2>/dev/null || echo "")"

    if [[ -z "${sink}" || -z "${source}" ]]; then
      echo "Error: No se pudieron detectar sink y source de audio con pactl." >&2
      exit 1
    fi

    sink_monitor="${sink}.monitor"

    echo "Iniciando grabación de audio (sistema + micrófono)..."
    echo "  Salida: ${sink_monitor}"
    echo "  Entrada: ${source}"
    echo "  Archivo: ${outfile}"

    # Ejecutar ffmpeg en background desacoplado con setsid para sobrevivir sesiones shell
    # amix mezcla ambas fuentes; duration=longest mantiene la grabación viva mientras cualquiera tenga audio
    setsid ffmpeg -nostdin -y -loglevel warning \
      -f pulse -i "${sink_monitor}" \
      -f pulse -i "${source}" \
      -filter_complex "amix=inputs=2:duration=longest" \
      -c:a libmp3lame -b:a 128k \
      "${outfile}" > "${logfile}" 2>&1 < /dev/null &

    rec_pid=$!
    echo "${rec_pid}" > "${PIDFILE}"
    cat <<EOF > "${METAFILE}"
pid=${rec_pid}
start_time=${ts}
file=${outfile}
label=${etiqueta}
sink=${sink}
source=${source}
EOF

    sleep 1
    if kill -0 "${rec_pid}" 2>/dev/null; then
      echo "✅ Grabación iniciada en background (PID ${rec_pid})."
      echo "Guardando en: ${outfile}"
    else
      echo "🔴 Error al iniciar ffmpeg. Revisa el log: ${logfile}" >&2
      rm -f "${PIDFILE}" "${METAFILE}"
      exit 1
    fi
    ;;

  stop)
    if [[ ! -f "${PIDFILE}" ]]; then
      echo "No hay ninguna grabación activa registrada."
      exit 0
    fi

    pid="$(cat "${PIDFILE}" 2>/dev/null || true)"
    target_file=""
    if [[ -f "${METAFILE}" ]]; then
      target_file="$(grep '^file=' "${METAFILE}" | cut -d'=' -f2- || true)"
    fi

    if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
      echo "Deteniendo grabación (PID ${pid})..."
      # Enviar SIGINT para que ffmpeg cierre el contenedor MP3 limpiamente
      kill -INT "${pid}" 2>/dev/null || true
      
      # Esperar hasta 5 segundos a que ffmpeg cierre
      count=0
      while kill -0 "${pid}" 2>/dev/null && [[ ${count} -lt 10 ]]; do
        sleep 0.5
        count=$((count + 1))
      done

      if kill -0 "${pid}" 2>/dev/null; then
        echo "Forzando cierre de proceso..."
        kill -KILL "${pid}" 2>/dev/null || true
      fi
    else
      echo "El proceso ${pid} ya no estaba corriendo."
    fi

    rm -f "${PIDFILE}" "${METAFILE}"

    if [[ -n "${target_file}" && -f "${target_file}" ]]; then
      size="$(du -h "${target_file}" | cut -f1)"
      echo "✅ Grabación finalizada exitosamente."
      echo "  Archivo: ${target_file}"
      echo "  Tamaño: ${size}"
    else
      echo "✅ Grabación detenida."
    fi
    ;;

  status)
    if [[ -f "${PIDFILE}" ]]; then
      pid="$(cat "${PIDFILE}" 2>/dev/null || true)"
      if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
        target_file="$(grep '^file=' "${METAFILE}" 2>/dev/null | cut -d'=' -f2- || echo 'desconocido')"
        start_t="$(grep '^start_time=' "${METAFILE}" 2>/dev/null | cut -d'=' -f2- || echo '')"
        current_size="$(du -h "${target_file}" 2>/dev/null | cut -f1 || echo '0B')"
        echo "🔴 GRABANDO (PID ${pid})"
        echo "  Inicio: ${start_t}"
        echo "  Archivo: ${target_file}"
        echo "  Tamaño actual: ${current_size}"
        exit 0
      fi
      rm -f "${PIDFILE}" "${METAFILE}"
    fi
    echo "⚪ Grabadora inactiva (sin grabación en curso)."
    ;;

  *)
    echo "Uso: $0 {start [etiqueta]|stop|status}"
    exit 1
    ;;
esac
