targetScope = 'subscription'

module rg_module '../resource_group/main.bicep' = {
  scope: subscription()
  name: 'resource_group'
  params: {
    name: 'sampleInfra'
    location: 'westeurope'
  }
}
