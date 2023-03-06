targetScope = 'subscription'

@minLength(1)
@maxLength(20)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param name string
param location string
param uniqueSuffix string
param registryName string = 'acr${name}${uniqueSuffix}'
param workspaceName string = 'ws-${name}-${uniqueSuffix}'
param insightsName string = 'ai-${name}-${uniqueSuffix}'
param databaseName string = 'mysql-${name}-${uniqueSuffix}'
param databaseAdminUser string = 'azureuser'
@secure()
param databaseAdminPassword string = take(newGuid(), 16)
param serverFarmName string = 'farm-${name}-${uniqueSuffix}'
@description('SKU name, must be minimum P1v2')
@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
param serverFarmSku string = 'P1v2'
param serverFarmKind string = 'linux'
param siteName string = 'site-${name}-${uniqueSuffix}'
param imageName string = 'nginx'
param virtualNetworkName string = 'vnet-${name}-${uniqueSuffix}'
param dnsZoneName string = '${name}${uniqueSuffix}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${name}-${uniqueSuffix}'
  location: location
  tags: {
    'environment-name': name
  }
}

module dns 'modules/dns.bicep' = {
  name: '${deployment().name}-zone'
  scope: resourceGroup
  params: {
    zoneName: dnsZoneName
    virtualNetworkName: virtualNetworkName
  }
}

module vnet 'modules/vnet.bicep' = {
  name: '${deployment().name}-vnet'
  scope: resourceGroup
  params: {
    virtualNetworkName: virtualNetworkName
    location: location
  }
}

module registry 'modules/registry.bicep' = {
  name: '${deployment().name}-registry'
  scope: resourceGroup
  params: {
    registryName: registryName
    location: location
  }
}

module database 'modules/mysql.bicep' = {
  name: '${deployment().name}-database'
  scope: resourceGroup
  params: {
    databaseName: databaseName
    location: location
    adminUser: databaseAdminUser
    adminPassword: databaseAdminPassword
    virtualNetworkName: virtualNetworkName
    dnsZoneName: dnsZoneName
  }
}

module insights 'modules/insights.bicep' = {
  name: '${deployment().name}-appinsights'
  scope: resourceGroup
  params: {
    insightsName: insightsName
    workspaceName: workspaceName
    location: location
  }
}

module serverFarm 'modules/serverFarm.bicep' = {
  name: '${deployment().name}-serverFarm'
  scope: resourceGroup
  params: {
    location: location
    serverFarmName: serverFarmName
    logAnalyticsWorkspaceName: workspaceName
    sku: serverFarmSku
    kind: serverFarmKind
  }
}

module site 'modules/site.bicep' = {
  name: '${deployment().name}-site'
  scope: resourceGroup
  params: {
    siteName: siteName
    location: location
    insightsName: insightsName
    imageName: imageName
    registryName: registryName
    serverFarmId: serverFarm.outputs.id
    dnsZoneName: dnsZoneName
    virtualNetworkName: virtualNetworkName
  }
}