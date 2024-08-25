@description('The prefix for the storage account and related resources')
@maxLength(8)
param prefix string

@description('The azure location of the storage resource')
param location string

@description('The azure storage sku\'s allowed for deployment')
@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_LRS'
  'Standard_ZRS'
])
param sku string = 'Standard_LRS'

@description('The type of identitie(s) to deploy for the storage account')
@allowed([
  'None'
  'SystemAssigned'
  'SystemAssigned,UserAssigned'
  'UserAssigned'
])
param identity string = 'None'

@description('Allow or disallow public network access')
@allowed([
  'Disabled'
  'Enabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Minimum TLS version support')
@allowed([
  'TLS1_0'
  'TLS1_1'
  'TLS1_2'
  'TLS1_3'
])
param minimumTlsVersion string = 'TLS1_2'

@description('Name of blob container to create')
param blobContainerNames string[] = []

resource userAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = if (contains(
  identity,
  'UserAssigned'
)) {
  name: '${prefix}_identity'
  location: location
}

resource storageaccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: toLower('${prefix}stg${uniqueString(resourceGroup().id)}')
  location: location
  kind: 'StorageV2'
  sku: {
    name: sku
  }
  identity: identity == 'None'
    ? null
    : identity == 'SystemAssigned'
        ? { type: 'SystemAssigned' }
        : {
            type: identity
            userAssignedIdentities: empty(userAssignedManagedIdentity.id)
              ? {}
              : { '${userAssignedManagedIdentity.id}': {} }
          }
  properties: {
    publicNetworkAccess: publicNetworkAccess
    minimumTlsVersion: minimumTlsVersion
  }
}

module containers 'containers.bicep' = {
  name: 'module_containers'
  params: {
    blobConatinerNames: blobContainerNames
    storageAccountName: storageaccount.name
  }
}

output systemAssignedPrincipalIdentity string = contains(identity, 'SystemAssigned')
  ? storageaccount.identity.principalId
  : ''
