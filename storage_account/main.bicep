@description('[Required] The prefix for the storage account and related resources')
@maxLength(8)
param prefix string

@description('[Required] The azure location of the storage resource')
param location string

@description('[Optional] The azure storage sku\'s allowed for deployment')
@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_LRS'
  'Standard_ZRS'
])
param sku string = 'Standard_LRS'

@description('[Optional] The type of identitie(s) to deploy for the storage account')
@allowed([
  'None'
  'SystemAssigned'
  'SystemAssigned,UserAssigned'
  'UserAssigned'
])
param identity string = 'None'

@description('[Optional] Allow or disallow public network access')
@allowed([
  'Disabled'
  'Enabled'
])
param publicNetworkAccess string = 'Enabled'

@description('[Optional] Minimum TLS version support')
@allowed([
  'TLS1_0'
  'TLS1_1'
  'TLS1_2'
  'TLS1_3'
])
param minimumTlsVersion string = 'TLS1_2'

@description('[Optional] Name of blob container to create')
param blobContainerNames string[] = []

@description('[Optional] The diagnostic settings of the service.')
param diagnosticSettings storageDiagnosticSettingType

@description('[Optional] The diagnostic settings of the blob service.')
param blobServiceDiagnosticSettings storageSubServiceDiagnosticSettingType

@description('[Optional] The customer managed encryption key configuration for the storage account.')
param customerManagedKey customerManagedKeyType

param userAssignedIdentityResourceId string?

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
    encryption: {
      keySource: !empty(customerManagedKey) ? 'Microsoft.Keyvault' : 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keyvaultproperties: !empty(customerManagedKey)
        ? {
            keyname: customerManagedKey!.keyName
            keyvaulturi: customerManagedKey!.keyVaultUri
            keyversion: '16f4adc608ca472cab597d41160a611f'
          }
        : null
      identity: !empty(userAssignedManagedIdentity.id) && contains(identity, 'UserAssigned')
        ? {
            userAssignedIdentity: userAssignedManagedIdentity.id
          }
        : null
    }
  }
  dependsOn: [
    roleAssignment
  ]
}

// Encryption Key

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = if (!empty(customerManagedKey) && !empty(customerManagedKey.?keyVaultName)) {
  name: customerManagedKey.?keyVaultName! ?? 'unkown'
  scope: empty(customerManagedKey.?keyVaultResourceGroupName)
    ? resourceGroup(customerManagedKey.?keyVaultResourceGroupName!)
    : resourceGroup()
}

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'e147488a-f6f5-4113-8e2d-b22465e65bf6' // Key Vault Crypto Service Encryption User
  scope: subscription()
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(customerManagedKey) && contains(
  identity,
  'UserAssigned'
)) {
  name: guid(userAssignedManagedIdentity.id)
  scope: keyVault
  properties: {
    principalId: userAssignedManagedIdentity.properties.principalId
    roleDefinitionId: roleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

// Managed Identity

resource userAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = if (contains(
  identity,
  'UserAssigned'
)) {
  name: '${prefix}_identity'
  location: location
}

// Diagnostic Configuration

resource storageAccount_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [
  for (diagnosticSetting, index) in (diagnosticSettings ?? []): {
    name: diagnosticSetting.?name ?? '${storageaccount.name}-diagnosticSettings'
    properties: {
      storageAccountId: diagnosticSetting.?storageAccountResourceId
      workspaceId: diagnosticSetting.?workspaceResourceId
      eventHubName: diagnosticSetting.?eventHub.?name
      eventHubAuthorizationRuleId: diagnosticSetting.?eventHub.?authorizationRuleResourceId
      metrics: [
        for group in (diagnosticSetting.?metricCategories ?? [{ category: 'AllMetrics' }]): {
          category: group.category
          enabled: group.?enabled ?? true
          timeGrain: null
        }
      ]
    }
    scope: storageaccount
  }
]

// Blob service configuration

module containers 'blob_service.bicep' = {
  name: 'module_containers'
  params: {
    storageAccountName: storageaccount.name
    blobConatinerNames: blobContainerNames
    blobServiceDiagnosticSettings: blobServiceDiagnosticSettings
  }
}

// Custom types

type storageDiagnosticSettingType = {
  @description('[Optional] The name of diagnostic setting. If skipped a setting name of the format `<storage_account_name>-diagnosticSettings` will be created')
  name: string?

  @description('[Optional] The metrics to be collected for the resource')
  metricCategories: {
    @description('[Required] Name of a Diagnostic Metric category for a resource type this setting is applied to. Set to `AllMetrics` to collect all metrics.')
    category: string

    @description('[Optional] Enable or disable the category explicitly. Default is `true`.')
    enabled: bool?
  }[]?

  @description('[Optional] Resource ID of the diagnostic log analytics workspace.')
  workspaceResourceId: string?

  @description('[Optional] Resource ID of the diagnostic storage account.')
  storageAccountResourceId: string?

  @description('[Optional] Event hub configuration of the diagnostic storage account')
  eventHub: eventHubDiagnosticSettingType?
}[]?

type storageSubServiceDiagnosticSettingType = {
  @description('[Optional] The name of diagnostic setting. If skipped a setting name of the format `<storage_account_name>-diagnosticSettings` will be created')
  name: string?

  @description('[Optional] The metrics to be collected for the resource')
  metricCategories: {
    @description('[Required] Name of a Diagnostic Metric category for a resource type this setting is applied to. Set to `AllMetrics` to collect all metrics.')
    category: string

    @description('[Optional] Enable or disable the category explicitly. Default is `true`.')
    enabled: bool?
  }[]?

  @description('[Optional] The name of logs that will be streamed. "allLogs" includes all possible logs for the resource. Set to `[]` to disable log collection.')
  logCategories: {
    categoryGroup: 'audit' | 'allLogs'
    enabled: bool?
  }[]?

  @description('[Optional] Resource ID of the diagnostic log analytics workspace. For security reasons, it is recommended to set diagnostic settings to send data to either storage account, log analytics workspace or event hub.')
  workspaceResourceId: string?

  @description('[Optional] Resource ID of the diagnostic storage account. For security reasons, it is recommended to set diagnostic settings to send data to either storage account, log analytics workspace or event hub.')
  storageAccountResourceId: string?

  @description('[Optional] Event hub configuration of the diagnostic storage account')
  eventHub: eventHubDiagnosticSettingType?
}[]?

type eventHubDiagnosticSettingType = {
  @description('[Required] Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.')
  name: string

  @description('[Required] Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
  authorizationRuleResourceId: string
}

type customerManagedKeyType = {
  @description('[Required] The name of a key vault for customer managed key.')
  keyVaultName: string

  @description('[Optional] The name of a resource group of the key vault if located in a different resource group than the storage account.')
  keyVaultResourceGroupName: string?

  @description('[Required] The URI of a key vault for customer managed key.')
  keyVaultUri: string

  @description('[Required] The name of the key used for encryption.')
  keyName: string

  @description('[Optional] User assigned identity to use when fetching the customer managed key. If used must also be specified in `managedIdentities.userAssignedResourceIds`. Required if no system assigned identity is available for use.')
  userAssignedIdentityResourceId: string?
}?

// Outputs

@description('Principal id of the system assigned identity if one was created. Results in `null` if skipped provisioning by user')
output systemAssignedPrincipalIdentity string? = contains(identity, 'SystemAssigned')
  ? storageaccount.identity.principalId
  : null

@description('Resource id of the storage account that was created')
output storageAccountId string = storageaccount.id
