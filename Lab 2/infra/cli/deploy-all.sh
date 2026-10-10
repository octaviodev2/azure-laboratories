#!/usr/bin/env bash
# Ejecuta todo el Lab 2 en orden. Pide las contraseñas una sola vez al inicio.
set -euo pipefail
cd "$(dirname "$0")" && source ./00-variables.sh

require_secret VM_ADMIN_PASSWORD "Contraseña para $VM_ADMIN_USER (VM)"
require_secret PSQL_ADMIN_PASSWORD "Contraseña para $PSQL_ADMIN_USER (PostgreSQL)"

for step in 01-vnet 02-vm 03-bastion 04-postgresql 05-pe-postgresql 06-database 08-storage 09-pe-blob 10-app-service; do
  echo "==> $step"
  "./$step.sh"
done

echo "Listo. Para ahorrar créditos: ./07-stop-start.sh stop"
