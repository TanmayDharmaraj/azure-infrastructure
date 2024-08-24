targetScope = 'subscription'

param name string
param location string = 'westeurope'

resource resource_group 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: '${name}_rg'
  location: location
}
