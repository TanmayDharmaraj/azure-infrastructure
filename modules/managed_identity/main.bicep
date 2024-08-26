@maxLength(8)
param prefix string

@description('[Required] The azure location of the storage resource')
param location string

resource userAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${prefix}_identity'
  location: location
}

@description('The resoruce id of the principal')
output id string = userAssignedManagedIdentity.id

@description('The client id of the principal')
output clientId string = userAssignedManagedIdentity.properties.clientId
