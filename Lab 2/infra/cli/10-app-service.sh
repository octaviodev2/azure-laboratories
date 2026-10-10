#!/usr/bin/env bash
# Video 13: plan Linux B1 + Web App Node 24 LTS con VNet Integration y Application Insights.
# Si el plan o la app del Lab 1 existen con otra configuración (F1/Windows), elimínalos antes:
# F1 no admite integración con red virtual.
set -euo pipefail
cd "$(dirname "$0")" && source ./00-variables.sh

az appservice plan create \
  --resource-group "$RG" --name "$ASP" --location "$LOCATION" \
  --is-linux --sku B1 \
  --tags "${TAGS[@]}"

# Integración de VNet (tráfico saliente) hacia la subred delegada de App Service.
az webapp create \
  --resource-group "$RG" --plan "$ASP" --name "$APP" \
  --runtime "$APP_RUNTIME" \
  --vnet "$VNET" --subnet "$SNET_APP" \
  --basic-auth Disabled \
  --tags "${TAGS[@]}"

# Application Insights del Lab 1 (basado en el workspace de Log Analytics); se crea si no existe.
LOG_ID=$(az monitor log-analytics workspace show -g "$RG" -n "$LOG" --query id -o tsv)
az monitor app-insights component show -g "$RG" --app "$APPI" -o none 2>/dev/null \
  || az monitor app-insights component create -g "$RG" --app "$APPI" --location "$LOCATION" \
       --kind web --application-type web --workspace "$LOG_ID" --tags "${TAGS[@]}" -o none
APPI_CS=$(az monitor app-insights component show -g "$RG" --app "$APPI" --query connectionString -o tsv)

az webapp config appsettings set -g "$RG" -n "$APP" -o none --settings \
  APPLICATIONINSIGHTS_CONNECTION_STRING="$APPI_CS" \
  ApplicationInsightsAgent_EXTENSION_VERSION="~3"

az webapp show -g "$RG" -n "$APP" \
  --query "{App:name, Estado:state, Pila:siteConfig.linuxFxVersion, Subred:virtualNetworkSubnetId, URL:defaultHostName}" -o json
