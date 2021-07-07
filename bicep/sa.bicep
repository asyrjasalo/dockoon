/*
------------------------------------------------------------------------------
PARAMETERS
------------------------------------------------------------------------------
*/

param sa_name string
param tags object

/*
------------------------------------------------------------------------------
RESOURCES
------------------------------------------------------------------------------
*/

resource sa 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: sa_name
  location: resourceGroup().location
  tags: tags
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
}

resource share 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-02-01' = {
  name: '${sa_name}/default/share'
  properties: {
    shareQuota: 1
  }
  dependsOn: [
    sa
  ]
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = {
  name: '${sa_name}/default/apis'
  properties: {
    publicAccess: 'Blob'
  }
  dependsOn: [
    sa
  ]
}

/*
------------------------------------------------------------------------------
OUTPUT
------------------------------------------------------------------------------
*/

output fileEndpoint string = sa.properties.primaryEndpoints.file
output blobEndpoint string = sa.properties.primaryEndpoints.blob
