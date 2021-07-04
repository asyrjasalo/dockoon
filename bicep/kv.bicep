/*
------------------------------------------------------------------------------
PARAMETERS
------------------------------------------------------------------------------
*/

param key_vault_name string
param uami_object_id string

/*
------------------------------------------------------------------------------
RESOURCES
------------------------------------------------------------------------------
*/

resource ap 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: '${key_vault_name}/add'
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
