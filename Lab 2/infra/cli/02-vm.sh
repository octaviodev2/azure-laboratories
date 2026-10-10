#!/usr/bin/env bash
# Videos 3 y 4: VM Windows Server 2025 en la subred de VM, sin puertos de entrada públicos.
set -euo pipefail
cd "$(dirname "$0")" && source ./00-variables.sh
require_secret VM_ADMIN_PASSWORD "Contraseña para $VM_ADMIN_USER"

# --nsg-rule NONE crea el NSG básico de la NIC sin reglas de entrada (puertos públicos: Ninguno).
# La IP pública se crea como en el video; con Bastion es opcional (--public-ip-address "" la omite).
az vm create \
  --resource-group "$RG" --name "$VM" --location "$LOCATION" \
  --image "$VM_IMAGE" --size "$VM_SIZE" \
  --security-type TrustedLaunch --enable-secure-boot true --enable-vtpm false \
  --admin-username "$VM_ADMIN_USER" --admin-password "$VM_ADMIN_PASSWORD" \
  --license-type Windows_Server \
  --vnet-name "$VNET" --subnet "$SNET_VM" \
  --public-ip-address "${VM}-ip" --public-ip-sku Standard \
  --nsg "${VM}-nsg" --nsg-rule NONE \
  --accelerated-networking true \
  --storage-sku Premium_LRS \
  --os-disk-delete-option Delete --nic-delete-option Delete \
  --tags "${TAGS[@]}"

# Diagnósticos de arranque con cuenta de almacenamiento administrada.
az vm boot-diagnostics enable -g "$RG" -n "$VM"

az vm show -g "$RG" -n "$VM" -d \
  --query "{VM:name, Estado:powerState, IPPrivada:privateIps, IPPublica:publicIps, Tamano:hardwareProfile.vmSize}" -o table
