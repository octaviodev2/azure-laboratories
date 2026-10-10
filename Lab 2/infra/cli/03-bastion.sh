#!/usr/bin/env bash
# Video 5: Azure Bastion SKU Developer (gratuito) para entrar a la VM sin exponer RDP.
set -euo pipefail
cd "$(dirname "$0")" && source ./00-variables.sh

az extension add --name bastion --upgrade --yes --only-show-errors

# El SKU Developer no usa IP pública ni la AzureBastionSubnet; se asocia directamente a la VNet.
az network bastion create \
  --resource-group "$RG" --name "$BASTION" --location "$LOCATION" \
  --vnet-name "$VNET" --sku Developer \
  --tags "${TAGS[@]}"

az network bastion show -g "$RG" -n "$BASTION" \
  --query "{Bastion:name, SKU:sku.name, Estado:provisioningState}" -o table

echo "Conéctate desde el portal: VM > Conectar > Bastión (usuario $VM_ADMIN_USER)."
echo "Dentro de la VM ejecuta 'ipconfig': la IPv4 debe ser 10.0.3.4."
