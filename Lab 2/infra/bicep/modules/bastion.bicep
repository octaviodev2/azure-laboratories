// Video 5: Azure Bastion SKU Developer (sin IP pública; se asocia directo a la VNet).
param location string
param tags object
param bastionName string
param vnetId string

resource bastion 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: bastionName
  location: location
  tags: tags
  sku: { name: 'Developer' }
  properties: {
    virtualNetwork: { id: vnetId }
  }
}
