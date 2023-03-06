param siteName string
param location string = resourceGroup().location // Location for all resources
param serverFarmId string
param insightsName string
param registryName string
param imageName string
param virtualNetworkName string
param dnsZoneName string

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: insightsName
}

resource registry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' existing = {
  name: registryName
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: virtualNetworkName
}

resource zone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: '${dnsZoneName}.azurewebsites.net'
}

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: siteName
  location: location
  kind: 'linux,container'
  properties: {
    serverFarmId: serverFarmId
    virtualNetworkSubnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'backends')
    vnetRouteAllEnabled: true
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${registry.properties.loginServer}/${imageName}'
      minTlsVersion: '1.2'
    }
  }
}

resource appSettings 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: appService
  name: 'appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
    XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
    DOCKER_REGISTRY_SERVER_URL: registry.properties.loginServer
    DOCKER_REGISTRY_SERVER_USERNAME: registry.listCredentials().username
    DOCKER_REGISTRY_SERVER_PASSWORD: registry.listCredentials().passwords[0].value
    WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
  }
}

resource appLogging 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: appService
  name: 'logs'
  properties: {
    applicationLogs: {
      fileSystem: {
        level: 'Warning'
      }
    }
    httpLogs: {
      fileSystem: {
        retentionInMb: 40
        enabled: true
      }
    }
    failedRequestsTracing: {
      enabled: true
    }
    detailedErrorMessages: {
      enabled: true
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: '${siteName}-private-endpoint'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'backends')
    }
    privateLinkServiceConnections: [
      {
        name: '${siteName}-private-link'
        properties: {
          privateLinkServiceId: appService.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpoint
  name: '${siteName}-dnsgroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${siteName}-zoneconfig'
        properties: {
          privateDnsZoneId: zone.id
        }
      }
    ]
  }
}

output defaultHostName string = appService.properties.defaultHostName
