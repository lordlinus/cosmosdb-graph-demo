@description('Cosmos DB account name')
param accountName string = uniqueString(resourceGroup().id)

@description('Location for the Cosmos DB account.')
param location string = resourceGroup().location

@description('The primary replica region for the Cosmos DB account.')
param primaryRegion string

@description('The secondary replica region for the Cosmos DB account.')
param secondaryRegion string

@description('The default consistency level of the Cosmos DB account.')
@allowed([
  'Eventual'
  'ConsistentPrefix'
  'Session'
  'BoundedStaleness'
  'Strong'
])
param defaultConsistencyLevel string = 'Session'

@description('Max stale requests. Required for BoundedStaleness. Valid ranges, Single Region: 10 to 1000000. Multi Region: 100000 to 1000000.')
@minValue(10)
@maxValue(2147483647)
param maxStalenessPrefix int = 100000

@description('Max lag time (seconds). Required for BoundedStaleness. Valid ranges, Single Region: 5 to 84600. Multi Region: 300 to 86400.')
@minValue(5)
@maxValue(86400)
param maxIntervalInSeconds int = 300

@description('Enable automatic failover for regions')
param automaticFailover bool = true

@description('The name for the Gremlin database')
param databaseName string = 'database01'

@description('The name for the Gremlin graph')
param graphName string = 'graph01'

@description('Maximum autoscale throughput for the graph')
@minValue(4000)
@maxValue(1000000)
param autoscaleMaxThroughput int = 10000

// @description('Maximum throughput for the graph')
// @minValue(4000)
// @maxValue(40000)
// param maxThroughput int = 4000

param partitionKey string

var accountName_var = toLower(accountName)
var consistencyPolicy = {
  Eventual: {
    defaultConsistencyLevel: 'Eventual'
  }
  ConsistentPrefix: {
    defaultConsistencyLevel: 'ConsistentPrefix'
  }
  Session: {
    defaultConsistencyLevel: 'Session'
  }
  BoundedStaleness: {
    defaultConsistencyLevel: 'BoundedStaleness'
    maxStalenessPrefix: maxStalenessPrefix
    maxIntervalInSeconds: maxIntervalInSeconds
  }
  Strong: {
    defaultConsistencyLevel: 'Strong'
  }
}

var singleLocation = [
  {
    locationName: primaryRegion
    failoverPriority: 0
    isZoneRedundant: false
  }
]
// var multiLocation = [
//   {
//     locationName: primaryRegion
//     failoverPriority: 0
//     isZoneRedundant: false
//   }
//   {
//     locationName: secondaryRegion
//     failoverPriority: 1
//     isZoneRedundant: false
//   }
// ]

resource accountName_resource 'Microsoft.DocumentDB/databaseAccounts@2021-07-01-preview' = {
  name: accountName_var
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    enableFreeTier: false
    capabilities: [
      {
        name: 'EnableGremlin'
      }
      // {
      //   name: 'EnableServerless'
      // }
    ]
    consistencyPolicy: consistencyPolicy[defaultConsistencyLevel]
    locations: singleLocation
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: automaticFailover
    createMode: 'Default'
  }
}

resource accountName_databaseName 'Microsoft.DocumentDB/databaseAccounts/gremlinDatabases@2021-07-01-preview' = {
  name: '${accountName_resource.name}/${databaseName}'
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource accountName_databaseName_graphName 'Microsoft.DocumentDB/databaseAccounts/gremlinDatabases/graphs@2021-07-01-preview' = {
  name: '${accountName_databaseName.name}/${graphName}'
  properties: {
    resource: {
      id: graphName
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/myPathToNotIndex/*'
          }
        ]
      }
      partitionKey: {
        paths: [
          '/${partitionKey}'
        ]
        kind: 'Hash'
      }
    }

    options: {
      // throughput: maxThroughput
      autoscaleSettings: {
        maxThroughput: autoscaleMaxThroughput
      }
    }
  }
}
