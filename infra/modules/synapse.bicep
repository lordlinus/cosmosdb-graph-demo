@description('Location for all resources.')
param location string = resourceGroup().location

@description('Ip address of the client accessing Synapse resource')
param clientIp string

@description('SQL Admin password')
param sqlAdminPassword string

param accountName string = uniqueString(resourceGroup().id)

var accountName_var = toLower(accountName)

resource synapseStorage 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: accountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
  }
}

resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: accountName_var
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    defaultDataLakeStorage: {
      accountUrl: 'https://${synapseStorage.name}.dfs.core.windows.net/'
      filesystem: 'default'
    }
    publicNetworkAccess: 'Enabled'
    sqlAdministratorLogin: 'sqladminuser'
    sqlAdministratorLoginPassword: sqlAdminPassword
  }
}

resource sparkPool 'Microsoft.Synapse/workspaces/bigDataPools@2021-06-01' = {
  name: accountName_var
  location: location
  parent: synapseWorkspace
  properties: {
    autoPause: {
      enabled: true
      delayInMinutes: 15
    }
    autoScale: {
      enabled: true
      minNodeCount: 1
      maxNodeCount: 3
    }
    sparkVersion: '3.1'
    nodeSize: 'Medium'
    nodeSizeFamily: 'MemoryOptimized'
    dynamicExecutorAllocation: {
      enabled: true
    }
  }
}

resource clientAccess 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  name: 'AllowAllWindowsAzureIps'
  parent: synapseWorkspace
  properties: {
    startIpAddress: clientIp
    endIpAddress: clientIp
  }
}
