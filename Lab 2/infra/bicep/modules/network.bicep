// Video 2: VNet 10.0.0.0/16 con subredes privadas para App Service, BD, VM, Private Endpoints y Bastion.
param location string
param tags object
param vnetName string
param addressPrefix string = '10.0.0.0/16'
param subnets object = {
  app: { name: 'snet-utvt-integradora-app-dev-mxc-001', prefix: '10.0.1.0/24' }
  db: { name: 'snet-utvt-integradora-db-dev-mxc-001', prefix: '10.0.2.0/24' }
  vm: { name: 'snet-utvt-integradora-vm-dev-mxc-001', prefix: '10.0.3.0/24' }
  pe: { name: 'snet-utvt-integradora-pe-dev-mxc-001', prefix: '10.0.4.0/24' }
  bastion: { name: 'AzureBastionSubnet', prefix: '10.0.5.0/26' }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: { addressPrefixes: [ addressPrefix ] }
    subnets: [
      for item in items(subnets): {
        name: item.value.name
        properties: {
          addressPrefix: item.value.prefix
          defaultOutboundAccess: false
          // App Service necesita la subred delegada para la VNet Integration.
          delegations: item.key == 'app'
            ? [ { name: 'webapp', properties: { serviceName: 'Microsoft.Web/serverFarms' } } ]
            : []
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output subnetIds object = {
  app: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnets.app.name)
  db: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnets.db.name)
  vm: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnets.vm.name)
  pe: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnets.pe.name)
}
