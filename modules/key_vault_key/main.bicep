@description('[Required] The name of the key vault')
param keyVaultName string

@description('[Optional] The resource group of in which the key vault exists. If skipped the key vault from the same resource group will be used.')
param resourceGroupName string?

@description('[Required] The name of the RSA encryption key to create.')
param keyName string

@description('[Optional] Array of JsonWebKeyOperation.')
@allowed([
  'decrypt'
  'encrypt'
  'sign'
  'unwrapKey'
  'verify'
  'wrapKey'
])
param keyOps array

@description('[Optional] The size of the key. Defaults to 2048.')
@allowed([
  2048
  3072
  4096
])
param keySize int = 2048

resource key_vault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
  scope: !empty(resourceGroupName) ? resourceGroup(resourceGroupName!) : resourceGroup()
}

resource key 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  name: keyName
  parent: key_vault
  properties: {
    keyOps: keyOps
    keySize: keySize
    curveName: ''
    kty: 'RSA'
    attributes: {
      enabled: true
    }
  }
}

@description('The name of the key that was created')
output keyName string = key.name
