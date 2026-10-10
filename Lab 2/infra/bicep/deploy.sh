#!/usr/bin/env bash
# Despliega main.bicep en el grupo de recursos del Lab 1. Las contraseñas se piden y no se guardan.
# Uso: ./deploy.sh            (despliega)
#      ./deploy.sh what-if    (solo muestra los cambios)
set -euo pipefail
cd "$(dirname "$0")"

RG="rg-utvt-integradora-dev-mxc-001"
az account set --subscription "Azure for Students"

read -r -s -p "Contraseña de la VM (adminazureuser): " VM_PASS; echo
read -r -s -p "Contraseña de PostgreSQL (adminpgdev): " PG_PASS; echo
ENTRA_ID=$(az ad signed-in-user show --query id -o tsv)
ENTRA_UPN=$(az ad signed-in-user show --query userPrincipalName -o tsv)

az deployment group "${1:-create}" \
  --resource-group "$RG" \
  --name "lab2-$(date +%Y%m%d%H%M%S)" \
  --template-file main.bicep \
  --parameters vmAdminPassword="$VM_PASS" psqlAdminPassword="$PG_PASS" \
               entraAdminObjectId="$ENTRA_ID" entraAdminPrincipalName="$ENTRA_UPN"
