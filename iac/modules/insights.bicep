param workspaceName string
param insightsName string
param location string = resourceGroup().location

resource workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: workspaceName
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource insights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: insightsName
  location: location
  kind: 'web'
  properties: { 
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
  }
}
