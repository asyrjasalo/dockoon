/*
------------------------------------------------------------------------------
PARAMETERS
------------------------------------------------------------------------------
*/

param uami_name string
param tags object

/*
------------------------------------------------------------------------------
RESOURCES
------------------------------------------------------------------------------
*/

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: uami_name
  tags: tags
  location: resourceGroup().location
}

/*
------------------------------------------------------------------------------
OUTPUTS
------------------------------------------------------------------------------
*/

output clientId string = uami.properties.clientId
output principalId string = uami.properties.principalId
