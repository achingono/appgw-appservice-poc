param databaseName string
param location string = resourceGroup().location
@allowed(['5.7', '8.0.21'])
param databaseVersion string = '5.7'
param adminUser string
@secure()
param adminPassword string
param storageSizeGB int = 20
param storageIops int = 360
@allowed(['Enabled', 'Disabled'])
param storageAutogrow string = 'Enabled'
@allowed(['Enabled', 'Disabled'])
param storageAutoIoScaling string = 'Disabled'
param backupRetentionDays int = 7
@allowed(['Enabled', 'Disabled'])
param geoRedundantBackup string = 'Disabled'
@allowed(['Disabled', 'SameZone', 'ZoneRedundant'])
param highAvailabilityMode string = 'Disabled'
param standbyAvailabilityZone string = ''
param dataEncryption object = {}
param skuName string = 'Standard_B1ms'
param skuEdition string = 'Burstable'
param virtualNetworkName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: virtualNetworkName
}

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.mysql.database.azure.com'
}

resource database 'Microsoft.DBforMySQL/flexibleServers@2021-12-01-preview' = {
  name: databaseName
  location: location
  properties: {
    version: databaseVersion
    administratorLogin: adminUser
    administratorLoginPassword: adminPassword
    network: {
      delegatedSubnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'storage')
      privateDnsZoneResourceId: dnsZone.id
    }
    storage: {
      storageSizeGB: storageSizeGB
      iops: storageIops
      autoGrow: storageAutogrow
      autoIoScaling: storageAutoIoScaling
    }
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
    highAvailability: {
      mode: highAvailabilityMode
      standbyAvailabilityZone: standbyAvailabilityZone
    }
    dataEncryption: dataEncryption
  }
  sku: {
    name : skuName
    tier: skuEdition
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: '${databaseName}-private-endpoint'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'storage')
    }
    privateLinkServiceConnections: [
      {
        name: '${databaseName}-private-link'
        properties: {
          privateLinkServiceId: database.id
          groupIds: [
            'flexibleServers'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpoint
  name: '${databaseName}-dnsgroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${databaseName}-zoneconfig'
        properties: {
          privateDnsZoneId: dnsZone.id
        }
      }
    ]
  }
}
