@description('[Required] Prefix to be used for the resource')
@minLength(3)
@maxLength(60)
param prefix string

@description('[Required] Location to deploy the resource to')
param location string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: '${prefix}law'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

@description('Resource ID of the Log Analytics Workspace that was created')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
