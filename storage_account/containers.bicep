param storageAccountName string
param blobConatinerNames string[]

resource storageaccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  name: 'default'
  parent: storageaccount
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = [
  for name in blobConatinerNames: {
    name: toLower(name)
    parent: blobService
    properties: {}
  }
]
