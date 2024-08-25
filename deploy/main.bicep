targetScope = 'subscription'

var prefix = 'sample'
var location = 'westeurope'
var diagnosticResourceGroupName = 'diag_rg'
var eventhubNamespaceName = 'diagns'
var eventhubNamespaceEventHubName = 'diagnostics'
var logAnalyticsWorkspaceName = 'diaglaw'
var diagnosticStorageAccountName = 'diagstgulwyeojxn54f2'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: '${prefix}_rg'
  location: location
}

resource diagnosticResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: diagnosticResourceGroupName
}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2024-01-01' existing = {
  name: eventhubNamespaceName
  scope: diagnosticResourceGroup
}

resource eventHubName 'Microsoft.EventHub/namespaces/eventhubs@2024-01-01' existing = {
  name: eventhubNamespaceEventHubName
  parent: eventHubNamespace
}

resource eventHubAuthorizationRule 'Microsoft.EventHub/namespaces/authorizationRules@2024-01-01' existing = {
  name: 'RootManageSharedAccessKey'
  parent: eventHubNamespace
}

resource logAnalyticsResource 'Microsoft.OperationalInsights/workspaces@2020-10-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: diagnosticResourceGroup
}

resource diagnosticStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: diagnosticStorageAccountName
  scope: diagnosticResourceGroup
}
module stg_module '../storage_account/main.bicep' = {
  name: 'module_storage'
  scope: resourceGroup
  params: {
    prefix: prefix
    location: location
    sku: 'Standard_LRS'
    identity: 'SystemAssigned,UserAssigned'
    blobContainerNames: [
      'container1'
      'container2'
    ]
    diagnosticSettings: [
      {
        name: 'diagnostic_setting'
        eventHub: {
          name: eventHubName.name
          authorizationRuleResourceId: eventHubAuthorizationRule.id
        }
        workspaceResourceId: logAnalyticsResource.id
        storageAccountResourceId: diagnosticStorageAccount.id
      }
    ]
    blobServiceDiagnosticSettings: [
      {
        name: 'blob_service_diagnostic_metric_setting'
        eventHub: {
          name: eventHubName.name
          authorizationRuleResourceId: eventHubAuthorizationRule.id
        }
        workspaceResourceId: logAnalyticsResource.id
        storageAccountResourceId: diagnosticStorageAccount.id
        logCategories: [
          {
            categoryGroup: 'allLogs'
            enabled: true
          }
        ]
      }
    ]
  }
}

output systemAssignedPrincipalIdForStorageAccount string = stg_module.outputs.systemAssignedPrincipalIdentity
