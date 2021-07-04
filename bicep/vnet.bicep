/*
------------------------------------------------------------------------------
PARAMETERS
------------------------------------------------------------------------------
*/

param vnet_name string
param tags object

param vnet_mask string = '172.16.128.0/24'
param public_subnet_name string = 'public'
param public_subnet_mask string = '172.16.128.0/25'
param private_subnet_name string = 'private'
param private_subnet_mask string = '172.16.128.128/25'

/*
------------------------------------------------------------------------------
VARIABLES
------------------------------------------------------------------------------
*/

var all_service_endpoints = [
  {
    service: 'Microsoft.AzureActiveDirectory'
    locations: [
      '*'
    ]
  }
  {
    service: 'Microsoft.AzureCosmosDB'
    locations: [
      '*'
    ]
  }
  {
    service: 'Microsoft.ContainerRegistry'
    locations: [
      '*'
    ]
  }
  {
    service: 'Microsoft.EventHub'
    locations: [
      '*'
    ]
  }
  {
    service: 'Microsoft.KeyVault'
    locations: [
      '*'
    ]
  }
  {
    service: 'Microsoft.ServiceBus'
    locations: [
      '*'
    ]
  }
  {
    service: 'Microsoft.Sql'
    locations: [
      '*'
    ]
  }
  {
    service: 'Microsoft.Storage'
    locations: [
      '*'
    ]
  }
  {
    service: 'Microsoft.Web'
    locations: [
      '*'
    ]
  }
]

/*
------------------------------------------------------------------------------
RESOURCES
------------------------------------------------------------------------------
*/

resource vnet 'Microsoft.Network/virtualNetworks@2020-07-01' = {
  name: vnet_name
  location: resourceGroup().location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_mask
      ]
    }
    subnets: [
      {
        name: public_subnet_name
        properties: {
          addressPrefix: public_subnet_mask
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: all_service_endpoints
          delegations: []
        }
      }
      {
        name: private_subnet_name
        properties: {
          addressPrefix: private_subnet_mask
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: all_service_endpoints
          delegations: [
            {
              name: 'aci'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
    ]
    enableDdosProtection: false
  }
}

/*
------------------------------------------------------------------------------
OUTPUTS
------------------------------------------------------------------------------
*/

output publicSubnetResourceId string = vnet.properties.subnets[0].id
output privateSubnetResourceId string = vnet.properties.subnets[1].id
