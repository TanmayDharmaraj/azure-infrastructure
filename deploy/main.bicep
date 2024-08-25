targetScope = 'subscription'

var prefix = 'sample'
var diagnosticResourceGroupPrefix = 'diag'
var location = 'westeurope'

resource diagnosticResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: '${diagnosticResourceGroupPrefix}_rg'
  location: location
}

module diagnosticStorageAccount '../storage_account/main.bicep' = {
  name: 'module_diagnostic_storage'
  scope: diagnosticResourceGroup
  params: {
    prefix: diagnosticResourceGroupPrefix
    location: location
    sku: 'Standard_LRS'
  }
}

module diagnosticLogAnalyticsAgent '../log_analytics_workspace/main.bicep' = {
  name: 'module_diagnostic_log_analytics_agent'
  scope: diagnosticResourceGroup
  params: {
    location: location
    prefix: diagnosticResourceGroupPrefix
  }
}

module diagnosticEventHub '../event_hub/main.bicep' = {
  scope: diagnosticResourceGroup
  name: 'module_diagnostic_event_hub'
  params: {
    location: location
    prefix: diagnosticResourceGroupPrefix
  }
}

// Storage
resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: '${prefix}_rg'
  location: location
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
          name: diagnosticEventHub.outputs.eventHubName
          authorizationRuleResourceId: diagnosticEventHub.outputs.authorizationRule
        }
        workspaceResourceId: diagnosticLogAnalyticsAgent.outputs.logAnalyticsWorkspaceId
        storageAccountResourceId: diagnosticStorageAccount.outputs.storageAccountId
      }
    ]
    blobServiceDiagnosticSettings: [
      {
        name: 'blob_service_diagnostic_metric_setting'
        eventHub: {
          name: diagnosticEventHub.outputs.eventHubName
          authorizationRuleResourceId: diagnosticEventHub.outputs.authorizationRule
        }
        workspaceResourceId: diagnosticLogAnalyticsAgent.outputs.logAnalyticsWorkspaceId
        storageAccountResourceId: diagnosticStorageAccount.outputs.storageAccountId
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
