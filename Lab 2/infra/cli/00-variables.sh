#!/usr/bin/env bash
# Variables compartidas del Lab 2 (proyecto integrador, ambiente dev).
# Los nombres siguen el Excel "Red y subredes.xlsx". Cargar con: source ./00-variables.sh

# --- Generales ---
export SUBSCRIPTION="Azure for Students"
export RG="rg-utvt-integradora-dev-mxc-001"
export LOCATION="mexicocentral"
export TAGS=(cost_center=utvt environment=dev managed_by=cli owner=equipo-integradora)

# --- Red ---
export VNET="vnet-utvt-integradora-dev-mxc-001"
export VNET_CIDR="10.0.0.0/16"
export SNET_APP="snet-utvt-integradora-app-dev-mxc-001";  export SNET_APP_CIDR="10.0.1.0/24"
export SNET_DB="snet-utvt-integradora-db-dev-mxc-001";    export SNET_DB_CIDR="10.0.2.0/24"
export SNET_VM="snet-utvt-integradora-vm-dev-mxc-001";    export SNET_VM_CIDR="10.0.3.0/24"
export SNET_PE="snet-utvt-integradora-pe-dev-mxc-001";    export SNET_PE_CIDR="10.0.4.0/24"
export SNET_BASTION="AzureBastionSubnet";                 export SNET_BASTION_CIDR="10.0.5.0/26"

# --- Máquina virtual y Bastion ---
export VM="vm-utvt-integradora-dev-mxc-001"
export VM_SIZE="Standard_B2als_v2"
export VM_IMAGE="MicrosoftWindowsServer:WindowsServer:2025-datacenter-g2:latest"
export VM_ADMIN_USER="adminazureuser"
export BASTION="${VNET}-bastion"

# --- PostgreSQL ---
export PSQL="psql-utvt-integradora-dev-mxc-001"
export PSQL_ADMIN_USER="adminpgdev"
export PSQL_VERSION="18"
export PSQL_DB="integradora"
export PEP_DB="pep-utvt-integradora-db-dev-mxc-001"
export NIC_PE_DB="nic-utvt-integradora-pe-db-dev-mxc-001"
export DNS_ZONE_PSQL="privatelink.postgres.database.azure.com"

# --- Storage ---
export STORAGE="stutvtintdevmxc001"
export PEP_BLOB="pep-utvt-integradora-blob-dev-mxc-001"
export NIC_PE_BLOB="nic-utvt-integradora-pe-blob-dev-mxc-001"
export DNS_ZONE_BLOB="privatelink.blob.core.windows.net"

# --- App Service y monitoreo (Lab 1) ---
export ASP="asp-utvt-integradora-dev-mxc-001"
export APP="app-utvt-integradora-web-dev-mxc-001"
export APP_RUNTIME="NODE:24-lts"
export APPI="appi-utvt-integradora-dev-mxc-001"
export LOG="log-utvt-integradora-dev-mxc-001"

# Las contraseñas NUNCA se guardan en el repo: se piden al ejecutar si no vienen en el entorno.
require_secret() {
  local var="$1" prompt="$2"
  if [[ -z "${!var:-}" ]]; then
    read -r -s -p "$prompt: " "$var"; echo
    export "$var"
  fi
}

az account set --subscription "$SUBSCRIPTION"
