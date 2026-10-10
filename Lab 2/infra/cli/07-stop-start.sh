#!/usr/bin/env bash
# Video 9: detener (o iniciar) la VM y el servidor PostgreSQL para no consumir créditos.
# Uso: ./07-stop-start.sh stop | start
set -euo pipefail
cd "$(dirname "$0")" && source ./00-variables.sh

case "${1:-stop}" in
  stop)
    az vm deallocate -g "$RG" -n "$VM"              # Detenido (desasignado): no cobra cómputo
    az postgres flexible-server stop -g "$RG" -n "$PSQL"  # Se reinicia solo tras 7 días
    ;;
  start)
    az vm start -g "$RG" -n "$VM"
    az postgres flexible-server start -g "$RG" -n "$PSQL"
    ;;
  *) echo "Uso: $0 stop|start" >&2; exit 1 ;;
esac

az vm show -g "$RG" -n "$VM" -d --query "{VM:name, Estado:powerState}" -o table
az postgres flexible-server show -g "$RG" -n "$PSQL" --query "{Servidor:name, Estado:state}" -o table
