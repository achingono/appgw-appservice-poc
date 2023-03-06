param zoneName string
param virtualNetworkName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: virtualNetworkName
}

resource siteZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${zoneName}.azurewebsites.net'
  location: 'global'
  dependsOn: [
    virtualNetwork
  ]
}

resource siteZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: siteZone
  name: '${siteZone.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

resource sqlZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${zoneName}.mysql.database.azure.com'
  location: 'global'
  dependsOn: [
    virtualNetwork
  ]
}

resource sqlZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: sqlZone
  name: '${sqlZone.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}
