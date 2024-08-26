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
    location: diagnosticResourceGroup.location
    sku: 'Standard_LRS'
  }
}

module diagnosticLogAnalyticsAgent '../log_analytics_workspace/main.bicep' = {
  name: 'module_diagnostic_log_analytics_agent'
  scope: diagnosticResourceGroup
  params: {
    location: diagnosticResourceGroup.location
    prefix: diagnosticResourceGroupPrefix
  }
}

module diagnosticEventHub '../event_hub/main.bicep' = {
  scope: diagnosticResourceGroup
  name: 'module_diagnostic_event_hub'
  params: {
    location: diagnosticResourceGroup.location
    prefix: diagnosticResourceGroupPrefix
  }
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: '${prefix}_rg'
  location: location
}

// Key vault (used for CMK)
module keyVault '../key_vault/main.bicep' = {
  scope: resourceGroup
  name: 'module_key_vault'
  params: {
    prefix: prefix
    location: resourceGroup.location
  }
}

module storageEncryptionKey '../key_vault_key/main.bicep' = {
  scope: resourceGroup
  name: 'module_key_vault_key'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    keyName: 'storage-encryption-key'
    keyOps: [
      'wrapKey'
      'unwrapKey'
    ]
  }
}

// Storage
module stg_module '../storage_account/main.bicep' = {
  name: 'module_storage'
  scope: resourceGroup
  params: {
    prefix: prefix
    location: resourceGroup.location
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
    publicNetworkAccess: 'Enabled'
    networkAccess: {
      bypass: 'AzureServices, Logging'
      defaultAction: 'Allow'
      ipRules: [
        {
          value: '192.168.1.1'
          action: 'Allow'
        }
      ]
      virtualNetworkRules: [
        {
          id: '/subscriptions/${subscription().id}/resourceGroups/tst1_rg/providers/Microsoft.Network/virtualNetworks/sample_virtual_network/subnets/default'
          action: 'Allow'
        }
      ]
    }
  }
}

@description('The principal id of the system assigned identity of the storage account. Can result in null if provisioning of system assigned identity was skipped')
output systemAssignedPrincipalIdForStorageAccount string? = stg_module.outputs.systemAssignedPrincipalIdentity
