#!/usr/bin/env bash
# Video 7: Private Endpoint de PostgreSQL en la subred de BD + zona privatelink.postgres.database.azure.com.
set -euo pipefail
cd "$(dirname "$0")" && source ./00-variables.sh && source ./lib-private-endpoint.sh

PSQL_ID=$(az postgres flexible-server show -g "$RG" -n "$PSQL" --query id -o tsv)

create_private_endpoint "$PEP_DB" "$NIC_PE_DB" "$SNET_DB" "$PSQL_ID" postgresqlServer "$DNS_ZONE_PSQL"
