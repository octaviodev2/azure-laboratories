#!/usr/bin/env bash
# Video 6: Azure Database for PostgreSQL flexible server (Burstable B1ms) sin acceso público.
set -euo pipefail
cd "$(dirname "$0")" && source ./00-variables.sh
require_secret PSQL_ADMIN_PASSWORD "Contraseña para $PSQL_ADMIN_USER"

# --public-access None: modo "acceso público y puntos de conexión privados" sin reglas de firewall
# y con el acceso público deshabilitado; el acceso real llega por el Private Endpoint (05).
az postgres flexible-server create \
  --resource-group "$RG" --name "$PSQL" --location "$LOCATION" \
  --version "$PSQL_VERSION" \
  --tier Burstable --sku-name Standard_B1ms \
  --storage-size 32 --storage-auto-grow Disabled \
  --high-availability Disabled --backup-retention 7 \
  --password-auth Enabled --microsoft-entra-auth Enabled \
  --admin-user "$PSQL_ADMIN_USER" --admin-password "$PSQL_ADMIN_PASSWORD" \
  --public-access None \
  --tags "${TAGS[@]}" \
  --yes

# Administrador de Microsoft Entra: el usuario con sesión iniciada en la CLI.
read -r ENTRA_ID ENTRA_UPN < <(az ad signed-in-user show --query "[id, userPrincipalName]" -o tsv | tr '\n' ' ')
az postgres flexible-server microsoft-entra-admin create \
  -g "$RG" -s "$PSQL" --object-id "$ENTRA_ID" --display-name "$ENTRA_UPN" --type User

az postgres flexible-server show -g "$RG" -n "$PSQL" \
  --query "{Servidor:name, Estado:state, Version:version, SKU:sku.name, AccesoPublico:network.publicNetworkAccess, FQDN:fullyQualifiedDomainName}" -o table
