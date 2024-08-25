@minLength(3)
@maxLength(60)
param prefix string
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

output id string = logAnalyticsWorkspace.id
