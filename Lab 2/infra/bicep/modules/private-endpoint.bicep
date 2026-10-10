// Videos 7 y 12: Private Endpoint con NIC de nombre propio, zona DNS privada y vínculo a la VNet.
param location string
param tags object
param name string
param nicName string
param subnetId string
param vnetId string
param targetResourceId string
@description('Subrecurso de destino: postgresqlServer, blob, ...')
param groupId string
param privateDnsZoneName string

resource pe 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    customNetworkInterfaceName: nicName
    subnet: { id: subnetId }
    privateLinkServiceConnections: [
      {
        name: name
        properties: { privateLinkServiceId: targetResourceId, groupIds: [ groupId ] }
      }
    ]
  }
}

resource zone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  tags: tags
}

resource link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: zone
  name: 'link-${last(split(vnetId, '/'))}'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnetId }
    registrationEnabled: false
  }
}

// Registra automáticamente el registro A del endpoint en la zona.
resource zoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: pe
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      { name: replace(privateDnsZoneName, '.', '-'), properties: { privateDnsZoneId: zone.id } }
    ]
  }
}
