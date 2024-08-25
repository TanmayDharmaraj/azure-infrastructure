@minLength(4)
@maxLength(48)
param prefix string
param location string
@description('Specifies the messaging tier for Event Hub Namespace.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param eventHubSku string = 'Basic'

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2024-01-01' = {
  name: '${prefix}ns'
  location: location
  sku: {
    name: eventHubSku
    tier: eventHubSku
    capacity: 1
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2024-01-01' = {
  name: 'diagnostics'
  parent: eventHubNamespace
  properties: {
    messageRetentionInDays: eventHubSku == 'Basic' ? 1 : 7
  }
}
