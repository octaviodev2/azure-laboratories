#!/usr/bin/env bash
# Video 8: base de datos "integradora" en el servidor flexible.
# Nota: --database-name ya no existe en az 2.9x; el parámetro correcto es -n/--name.
set -euo pipefail
cd "$(dirname "$0")" && source ./00-variables.sh

az postgres flexible-server db create \
  --resource-group "$RG" \
  --server-name "$PSQL" \
  -n "$PSQL_DB"

az postgres flexible-server db list -g "$RG" -s "$PSQL" \
  --query "[].{BaseDeDatos:name, Charset:charset, Collation:collation}" -o table
