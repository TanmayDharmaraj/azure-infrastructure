targetScope = 'subscription'

var prefix = 'diag'
var location = 'westeurope'

resource resource_group 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: '${prefix}_rg'
  location: location
}

module stg_diagnostics_storage '../storage_account/main.bicep' = {
  name: 'module_diagnostic_storage'
  scope: resource_group
  params: {
    prefix: prefix
    location: location
    sku: 'Standard_LRS'
  }
}

module log_analytics_agent '../log_analytics_workspace/main.bicep' = {
  scope: resource_group
  name: 'module_log_analytics_agent'
  params: {
    location: location
    prefix: prefix
  }
}

module event_hub '../event_hub/main.bicep' = {
  scope: resource_group
  name: 'module_event_hub'
  params: {
    location: location
    prefix: prefix
  }
}
