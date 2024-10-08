@export()
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

@export()
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

@export()
type eventHubDiagnosticSettingType = {
  @description('[Required] Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.')
  name: string

  @description('[Required] Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
  authorizationRuleResourceId: string
}

@export()
type networkAccessType = {
  @description('[Optional] Enable or disable public network access. Default is `Allow`')
  defaultAction: 'Allow' | 'Deny'?

  @description('[Optional] IP Addresses to be applied.')
  ipRules: ipRuleType[]?

  @description('[Optional] Services to bypass')
  bypass:
    | 'AzureServices'
    | 'Logging'
    | 'Metrics'
    | 'AzureServices, Logging'
    | 'AzureServices, Metrics'
    | 'AzureServices, Logging, Metrics'
    | 'Logging, Metrics'
    | 'None'?

  @description('[Optional] The virtual network rules for the resource')
  virtualNetworkRules: virtualNetworkRuleType[]?
}

@export()
type ipRuleType = {
  @description('[Optional] value of the ip rule')
  value: string

  action: 'Allow'
}

@export()
type virtualNetworkRuleType = {
  @description('[Optional] The resource id of the virtual network')
  id: string

  action: 'Allow'
}
