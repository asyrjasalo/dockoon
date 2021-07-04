/*
------------------------------------------------------------------------------
PARAMETERS
------------------------------------------------------------------------------
*/

param sa_name string
param tags object
param private_subnet_id string

/*
------------------------------------------------------------------------------
VARIABLES
------------------------------------------------------------------------------
*/

var sa_fs_name = 'share'

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
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: private_subnet_id
          action: 'Allow'
        }
      ]
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
}

resource share 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-02-01' = {
  name: '${sa_name}/default/${sa_fs_name}'
  properties: {
    shareQuota: 1
    enabledProtocols: 'SMB'
  }
  dependsOn: [
    sa
  ]
}
