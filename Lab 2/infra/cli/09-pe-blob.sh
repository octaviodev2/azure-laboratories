#!/usr/bin/env bash
# Video 12: Private Endpoint de Blob en la subred de Private Endpoints + zona privatelink.blob.core.windows.net.
set -euo pipefail
cd "$(dirname "$0")" && source ./00-variables.sh && source ./lib-private-endpoint.sh

STORAGE_ID=$(az storage account show -g "$RG" -n "$STORAGE" --query id -o tsv)

create_private_endpoint "$PEP_BLOB" "$NIC_PE_BLOB" "$SNET_PE" "$STORAGE_ID" blob "$DNS_ZONE_BLOB"
