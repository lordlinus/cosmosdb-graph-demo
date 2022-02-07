@description('Container registry name')
param registryName string = uniqueString(resourceGroup().id)

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name : registryName
  location : 'southeastasia'
  sku : {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}
