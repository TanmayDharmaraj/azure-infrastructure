@description('[Required] Prefix to be used for the resource')
@minLength(3)
@maxLength(60)
param prefix string

@description('[Required] Location to deploy the resource to')
param location string

@description('[Optional] The tags for the resource')
param tags object?

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: '${prefix}law'
  location: location
  tags: union(tags ?? {}, resourceGroup().tags)
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

@description('Resource ID of the Log Analytics Workspace that was created')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
