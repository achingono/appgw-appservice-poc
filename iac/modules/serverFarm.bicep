param serverFarmName string = uniqueString(resourceGroup().id)
param location string = resourceGroup().location // Location for all resources
param sku string = 'S1' // The SKU of App Service Plan
param kind string = 'linux'
param logAnalyticsWorkspaceName string 

resource serverFarm 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: serverFarmName
  location: location
  properties: {
    reserved: true
  }
  sku: {
    name: sku
  }
  kind: kind
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = {
  name: logAnalyticsWorkspaceName
}

resource diagnosticLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: serverFarm.name
  scope: serverFarm
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true 
        }
      }
    ]
  }
}

output id string = serverFarm.id
