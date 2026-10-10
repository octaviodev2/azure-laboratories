// Videos 3 y 4: VM Windows Server 2025 (Trusted Launch) en la subred de VM, sin puertos de entrada públicos.
param location string
param tags object
param vmName string
param subnetId string
param vmSize string = 'Standard_B2als_v2'
param adminUsername string
@secure()
param adminPassword string
@description('El video crea IP pública; con Bastion no es necesaria.')
param createPublicIp bool = true

// NSG básico de la NIC sin reglas de entrada (puertos públicos: Ninguno).
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: '${vmName}-nsg'
  location: location
  tags: tags
  properties: { securityRules: [] }
}

resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = if (createPublicIp) {
  name: '${vmName}-ip'
  location: location
  tags: tags
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: '${vmName}-nic'
  location: location
  tags: tags
  properties: {
    enableAcceleratedNetworking: true
    networkSecurityGroup: { id: nsg.id }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: subnetId }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: createPublicIp ? { id: pip.id, properties: { deleteOption: 'Delete' } } : null
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: { vmSize: vmSize }
    licenseType: 'Windows_Server' // Ventaja híbrida de Azure (licencia de Azure for Students)
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: { secureBootEnabled: true, vTpmEnabled: false }
    }
    osProfile: {
      computerName: take(vmName, 15)
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2025-datacenter-g2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        deleteOption: 'Delete'
        managedDisk: { storageAccountType: 'Premium_LRS' }
      }
    }
    networkProfile: {
      networkInterfaces: [ { id: nic.id, properties: { deleteOption: 'Delete' } } ]
    }
    diagnosticsProfile: { bootDiagnostics: { enabled: true } } // cuenta de almacenamiento administrada
  }
}

output vmId string = vm.id
