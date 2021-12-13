targetScope = 'subscription'

// General parameters
@description('specify location')
param location string

@allowed([
  'dev'
  'tst'
  'prod'
])
@description('Specifies the environment of the deployment.')
param environment string = 'dev'

@minLength(2)
@maxLength(10)
@description('Specifies the prefix for all resources created in this deployment.')
param prefix string

@description('The primary replica region for the Cosmos DB account.')
param primaryRegion string

@description('The secondary replica region for the Cosmos DB account.')
param secondaryRegion string

@description('Maximum autoscale throughput for the graph')
@minValue(400)
@maxValue(4000)
param maxThroughput int

param partitionKey string

var name = toLower('${prefix}-${environment}')

resource demoResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${name}-rg'
  location: location
}

module cosmos 'modules/cosmos.bicep' = {
  scope: demoResourceGroup
  name: 'cosmosdb'
  params: {
    primaryRegion: primaryRegion
    secondaryRegion: secondaryRegion
    maxThroughput: maxThroughput
    partitionKey: partitionKey
  }
}
