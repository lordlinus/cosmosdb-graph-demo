targetScope = 'resourceGroup'

// var config = json(loadTextContent('./params.dev.json'))

// General parameters
@description('specify location')
param location string

// @allowed([
//   'dev'
//   'test'
//   'prod'
// ])
// @description('Specifies the environment of the deployment.')
// param environment string = 'test'

// @minLength(2)
// @maxLength(10)
// @description('Specifies the prefix for all resources created in this deployment.')
// param prefix string

@description('The primary replica region for the Cosmos DB account.')
param primaryRegion string

// @description('The secondary replica region for the Cosmos DB account.')
// param secondaryRegion string

@description('Cosmos database name')
param databaseName string

@description('Gremlin container name')
param graphName string

@description('Maximum autoscale throughput for the graph')
@minValue(400)
@maxValue(20000)
param maxThroughput int

param partitionKey string

@description('Ip address of the client accessing Synapse resource')
param clientIp string

@description('SQL Admin password')
param sqlAdminPassword string

@description('Cosmos account name')
param cosmosAccountName string

@description('Search service name')
param searchServiceName string

@description('Synapse workspace name')
param synapseWkspName string

@description('Synapse service storagename')
param storageAccountName string

@description('Azure Container Registry name')
param containerRegistryName string

param resourceGroupName string

module cosmos 'modules/cosmos.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'cosmosdb'
  params: {
    accountName: cosmosAccountName
    location: location
    primaryRegion: primaryRegion
    // secondaryRegion: secondaryRegion
    autoscaleMaxThroughput: maxThroughput
    partitionKey: partitionKey
    databaseName: databaseName
    graphName: graphName
  }
}

module search 'modules/search.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'search'
  params: {
    searchServiceName: searchServiceName
    location: location
  }
}

module spark 'modules/synapse.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'synapse'
  params: {
    location: location
    synapseWkspName: synapseWkspName
    storageAccountName: storageAccountName
    clientIp: clientIp
    sqlAdminPassword: sqlAdminPassword
  }
}

module registry 'modules/acr.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'registry'
  params: {
    containerRegistryName: containerRegistryName
    location: location
  }
}
