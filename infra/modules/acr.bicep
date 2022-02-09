@description('Container registry name')
param registryName string = uniqueString(resourceGroup().id)

@description('Location for the container registry.')
param location string = resourceGroup().location

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: registryName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
  }
}

output loginServer string = containerRegistry.properties.loginServer
