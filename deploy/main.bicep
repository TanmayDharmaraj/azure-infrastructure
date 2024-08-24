targetScope = 'subscription'

var prefix = 'sampleInfra'
var location = 'westeurope'

resource resource_group 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: '${prefix}_rg'
  location: location
}

module stg_module '../storage_account/main.bicep' = {
  name: 'module_storage'
  scope: resource_group
  params: {
    prefix: prefix
    location: location
    sku: 'Standard_LRS'
    identity: 'SystemAssigned,UserAssigned'
  }
}

output systemAssignedPrincipalIdForStorageAccount string = stg_module.outputs.systemAssignedPrincipalIdentity
