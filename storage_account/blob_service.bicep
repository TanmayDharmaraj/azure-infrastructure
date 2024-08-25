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
