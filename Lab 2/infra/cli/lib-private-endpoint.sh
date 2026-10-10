#!/usr/bin/env bash
# Crea un Private Endpoint con NIC de nombre propio y lo integra a una zona DNS privada.
# Uso: create_private_endpoint <pe> <nic> <subred> <resource-id> <group-id> <zona-dns>
create_private_endpoint() {
  local pe="$1" nic="$2" subnet="$3" resource_id="$4" group_id="$5" zone="$6"

  az network private-endpoint create \
    --resource-group "$RG" --name "$pe" --location "$LOCATION" \
    --vnet-name "$VNET" --subnet "$subnet" \
    --private-connection-resource-id "$resource_id" --group-id "$group_id" \
    --connection-name "$pe" --nic-name "$nic" \
    --tags "${TAGS[@]}"

  # Zona DNS privada + vínculo a la VNet (si ya existen, se reutilizan).
  az network private-dns zone show -g "$RG" -n "$zone" -o none 2>/dev/null \
    || az network private-dns zone create -g "$RG" -n "$zone" --tags "${TAGS[@]}" -o none
  az network private-dns link vnet show -g "$RG" -z "$zone" -n "link-$VNET" -o none 2>/dev/null \
    || az network private-dns link vnet create -g "$RG" -z "$zone" -n "link-$VNET" \
         --virtual-network "$VNET" --registration-enabled false -o none

  # Registra automáticamente el registro A del endpoint en la zona.
  az network private-endpoint dns-zone-group create \
    --resource-group "$RG" --endpoint-name "$pe" --name default \
    --private-dns-zone "$zone" --zone-name "${zone//./-}" -o none

  az network private-endpoint show -g "$RG" -n "$pe" \
    --query "{Endpoint:name, IP:customDnsConfigs[0].ipAddresses[0], FQDN:customDnsConfigs[0].fqdn, Estado:privateLinkServiceConnections[0].privateLinkServiceConnectionState.status}" -o table
}
