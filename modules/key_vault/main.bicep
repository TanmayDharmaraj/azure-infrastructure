@description('[Required] The prefix for the key vault and its related resources')
@maxLength(8)
param prefix string

@description('[Required] The azure location of the storage resource')
param location string

@description('[Optional] The sku for the key vault')
@allowed([
  'premium'
  'standard'
])
param sku string = 'standard'

@description('[Optional] The tags for the resource')
param tags object?

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: toLower('${prefix}-${uniqueString(resourceGroup().id)}-kv')
  location: location
  tags: union(tags ?? {}, resourceGroup().tags)
  properties: {
    sku: {
      name: sku
      family: 'A'
    }
    tenantId: tenant().tenantId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableRbacAuthorization: true
  }
}

@description('The resource id of the provisioned key vault')
output keyVaultResourceId string = keyVault.id

@description('The name of the provisioned key vault')
output keyVaultName string = keyVault.name

@description('The URI of the provisioned key vault')
output keyVaultUri string = keyVault.properties.vaultUri
