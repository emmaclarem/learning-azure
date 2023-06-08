// PARAMETERS ---------------------------------------------------------------------------
@description('The storage account location.')
param location string = resourceGroup().location

// @description('The number of storage accounts to create.')
// param storageCount int

@description('The storage account access tier. True is Hot, False is Cool.')
param accessTier bool

@description('The storage account redundancy. True is GRS, False is LRS.')
param globalRedundancy bool


// VARIABLES ---------------------------------------------------------------------------
var storagePrefix = 'em'
var containerName = 'container'


// RESOURCE DEPLOYMENTS ---------------------------------------------------------------------------
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: '${storagePrefix}${uniqueString(resourceGroup().id)}'
  location: location
  tags: {
    project: 'Bicep'
    environment: 'Development'
  }
  kind: 'StorageV2'
  sku: {
    name: globalRedundancy ? 'Standard_GRS' : 'Standard_LRS'
  }
  properties: {
    accessTier: accessTier ? 'Hot' : 'Cool'
  }
}

resource service 'Microsoft.Storage/storageAccounts/blobServices@2021-02-01' = {
  parent: storageAccount
  name: 'default'
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' =  {
  parent: service
  name: '${uniqueString(resourceGroup().id)}${containerName}'
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}


// OUTPUTS ---------------------------------------------------------------------------
output storageInfo array = [{
  id: storageAccount.id
  blobPrimaryEndpoint : storageAccount.properties.primaryEndpoints.blob
}]
