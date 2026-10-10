#!/usr/bin/env bash
# Video 2: red virtual 10.0.0.0/16 con subredes para App Service, BD, VM, Private Endpoints y Bastion.
set -euo pipefail
cd "$(dirname "$0")" && source ./00-variables.sh

az network vnet create \
  --resource-group "$RG" --name "$VNET" --location "$LOCATION" \
  --address-prefixes "$VNET_CIDR" \
  --tags "${TAGS[@]}"

# Subredes privadas (sin acceso de salida predeterminado), igual que en el portal.
# La subred de App Service se delega a Microsoft.Web/serverFarms para la VNet Integration.
az network vnet subnet create -g "$RG" --vnet-name "$VNET" \
  --name "$SNET_APP" --address-prefixes "$SNET_APP_CIDR" \
  --delegations Microsoft.Web/serverFarms --default-outbound-access false

for pair in "$SNET_DB:$SNET_DB_CIDR" "$SNET_VM:$SNET_VM_CIDR" "$SNET_PE:$SNET_PE_CIDR" "$SNET_BASTION:$SNET_BASTION_CIDR"; do
  az network vnet subnet create -g "$RG" --vnet-name "$VNET" \
    --name "${pair%%:*}" --address-prefixes "${pair#*:}" \
    --default-outbound-access false
done

az network vnet subnet list -g "$RG" --vnet-name "$VNET" \
  --query "[].{Subred:name, CIDR:addressPrefix}" -o table
