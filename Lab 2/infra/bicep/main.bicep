// Lab 2: infraestructura del proyecto integrador (ambiente dev) en el grupo de recursos existente.
// Desplegar con deploy.sh (crea el despliegue a nivel de grupo de recursos).
targetScope = 'resourceGroup'

param location string = 'mexicocentral'
param tags object = {
  cost_center: 'utvt'
  environment: 'dev'
  managed_by: 'bicep'
  owner: 'equipo-integradora'
}

param vnetName string = 'vnet-utvt-integradora-dev-mxc-001'
param vmName string = 'vm-utvt-integradora-dev-mxc-001'
param vmAdminUsername string = 'adminazureuser'
@secure()
param vmAdminPassword string
param psqlName string = 'psql-utvt-integradora-dev-mxc-001'
param psqlAdminLogin string = 'adminpgdev'
@secure()
param psqlAdminPassword string
param entraAdminObjectId string
param entraAdminPrincipalName string
param storageName string = 'stutvtintdevmxc001'
param planName string = 'asp-utvt-integradora-dev-mxc-001'
param appName string = 'app-utvt-integradora-web-dev-mxc-001'
param appInsightsName string = 'appi-utvt-integradora-dev-mxc-001'
param logAnalyticsName string = 'log-utvt-integradora-dev-mxc-001'

module network 'modules/network.bicep' = {
  name: 'network'
  params: { location: location, tags: tags, vnetName: vnetName }
}

module vm 'modules/vm.bicep' = {
  name: 'vm'
  params: {
    location: location
    tags: tags
    vmName: vmName
    subnetId: network.outputs.subnetIds.vm
    adminUsername: vmAdminUsername
    adminPassword: vmAdminPassword
  }
}

module bastion 'modules/bastion.bicep' = {
  name: 'bastion'
  params: { location: location, tags: tags, bastionName: '${vnetName}-bastion', vnetId: network.outputs.vnetId }
}

module postgresql 'modules/postgresql.bicep' = {
  name: 'postgresql'
  params: {
    location: location
    tags: tags
    serverName: psqlName
    adminLogin: psqlAdminLogin
    adminPassword: psqlAdminPassword
    entraAdminObjectId: entraAdminObjectId
    entraAdminPrincipalName: entraAdminPrincipalName
  }
}

module pePostgres 'modules/private-endpoint.bicep' = {
  name: 'pe-postgresql'
  params: {
    location: location
    tags: tags
    name: 'pep-utvt-integradora-db-dev-mxc-001'
    nicName: 'nic-utvt-integradora-pe-db-dev-mxc-001'
    subnetId: network.outputs.subnetIds.db
    vnetId: network.outputs.vnetId
    targetResourceId: postgresql.outputs.serverId
    groupId: 'postgresqlServer'
    privateDnsZoneName: 'privatelink.postgres.database.azure.com'
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: { location: location, tags: tags, accountName: storageName }
}

module peBlob 'modules/private-endpoint.bicep' = {
  name: 'pe-blob'
  params: {
    location: location
    tags: tags
    name: 'pep-utvt-integradora-blob-dev-mxc-001'
    nicName: 'nic-utvt-integradora-pe-blob-dev-mxc-001'
    subnetId: network.outputs.subnetIds.pe
    vnetId: network.outputs.vnetId
    targetResourceId: storage.outputs.accountId
    groupId: 'blob'
    privateDnsZoneName: 'privatelink.blob.core.windows.net'
  }
}

module appService 'modules/app-service.bicep' = {
  name: 'app-service'
  params: {
    location: location
    tags: tags
    planName: planName
    appName: appName
    appInsightsName: appInsightsName
    logAnalyticsName: logAnalyticsName
    integrationSubnetId: network.outputs.subnetIds.app
  }
}

output postgresFqdn string = postgresql.outputs.fqdn
output webAppUrl string = 'https://${appService.outputs.defaultHostName}'
