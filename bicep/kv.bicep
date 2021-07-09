/*
------------------------------------------------------------------------------
PARAMETERS
------------------------------------------------------------------------------
*/

param key_vault_name string
param uami_object_id string

/*
------------------------------------------------------------------------------
EXISTING RESOURCES
------------------------------------------------------------------------------
*/

resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: key_vault_name
}

/*
------------------------------------------------------------------------------
RESOURCES
------------------------------------------------------------------------------
*/

resource ap 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  parent: kv
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: uami_object_id
        permissions: {
          secrets: [
            'get'
          ]
          certificates: [
            'get'
          ]
        }
      }
    ]
  }
}
