@description('[Required] Prefix to be used for event hub resources')
@minLength(4)
@maxLength(48)
param prefix string

@description('[Required] Location to deploy the resource to')
param location string

@description('[Optional] Specifies the messaging tier for Event Hub Namespace. Defaults to `Basic`')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param eventHubSku string = 'Basic'

@description('[Optional] The tags for the resource')
param tags object?

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2024-01-01' = {
  name: '${prefix}ns'
  location: location
  tags: union(tags ?? {}, resourceGroup().tags)
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

resource eventHubAuthorizationRule 'Microsoft.EventHub/namespaces/authorizationRules@2024-01-01' existing = {
  name: 'RootManageSharedAccessKey'
  parent: eventHubNamespace
}

@description('Namespace of the event hub that was created')
output eventHubNamespaceName string = eventHubNamespace.name

@description('Name of the event hub that was created')
output eventHubName string = eventHub.name

@description('Resource id of the default `RootManageSharedAccessKey` authorization rule')
output authorizationRule string = eventHubAuthorizationRule.id
