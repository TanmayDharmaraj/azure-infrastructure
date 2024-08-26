import { storageSubServiceDiagnosticSettingType } from 'types.bicep'

@description('[Required] The name of the storage account')
param storageAccountName string

@description('[Optional] A list of containers to create')
param blobConatinerNames string[] = []

@description('[Optional] The diagnostic settings of the blob service.')
param blobServiceDiagnosticSettings storageSubServiceDiagnosticSettingType

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

resource blobServiceLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [
  for (diagnosticSetting, index) in (blobServiceDiagnosticSettings ?? []): {
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
      logs: [
        for log in (diagnosticSetting.?logCategories ?? []): {
          categoryGroup: log.categoryGroup
          enabled: log.?enabled ?? true
        }
      ]
    }
    scope: blobService
  }
]
