#!/usr/bin/env bash
# Video 11: cuenta de almacenamiento (Blob, Standard LRS) sin acceso de red pública.
set -euo pipefail
cd "$(dirname "$0")" && source ./00-variables.sh

az storage account create \
  --resource-group "$RG" --name "$STORAGE" --location "$LOCATION" \
  --kind StorageV2 --sku Standard_LRS --access-tier Hot \
  --public-network-access Disabled \
  --https-only true --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --tags "${TAGS[@]}"

# Protección de datos: eliminación temporal de blobs y contenedores (7 días).
az storage account blob-service-properties update \
  --resource-group "$RG" --account-name "$STORAGE" \
  --enable-delete-retention true --delete-retention-days 7 \
  --enable-container-delete-retention true --container-delete-retention-days 7 -o none

az storage account show -g "$RG" -n "$STORAGE" \
  --query "{Cuenta:name, SKU:sku.name, AccesoPublico:publicNetworkAccess, TLS:minimumTlsVersion}" -o table
