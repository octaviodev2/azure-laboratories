// Videos 6 y 8: PostgreSQL flexible server Burstable B1ms sin acceso público + base "integradora".
param location string
param tags object
param serverName string
param version string = '18'
param adminLogin string
@secure()
param adminPassword string
param databaseName string = 'integradora'
@description('Object ID y UPN del administrador de Microsoft Entra.')
param entraAdminObjectId string
param entraAdminPrincipalName string

resource server 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: serverName
  location: location
  tags: tags
  sku: { name: 'Standard_B1ms', tier: 'Burstable' }
  properties: {
    version: version
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
    authConfig: { passwordAuth: 'Enabled', activeDirectoryAuth: 'Enabled', tenantId: tenant().tenantId }
    storage: { storageSizeGB: 32, autoGrow: 'Disabled' }
    backup: { backupRetentionDays: 7, geoRedundantBackup: 'Disabled' }
    highAvailability: { mode: 'Disabled' }
    // Acceso público deshabilitado: solo se llega por el Private Endpoint.
    network: { publicNetworkAccess: 'Disabled' }
  }
}

resource entraAdmin 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2024-08-01' = {
  parent: server
  name: entraAdminObjectId
  properties: {
    principalType: 'User'
    principalName: entraAdminPrincipalName
    tenantId: tenant().tenantId
  }
}

resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = {
  parent: server
  name: databaseName
  properties: { charset: 'UTF8', collation: 'en_US.utf8' }
  dependsOn: [ entraAdmin ]
}

output serverId string = server.id
output fqdn string = server.properties.fullyQualifiedDomainName
