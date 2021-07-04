/*
------------------------------------------------------------------------------
PARAMETERS
------------------------------------------------------------------------------
*/

param vnet_name string
param tags object

/*
------------------------------------------------------------------------------
VARIABLES
------------------------------------------------------------------------------
*/

var vnet_mask = '172.16.128.0/24'
var public_subnet_name = 'public'
var public_subnet_mask = '172.16.128.0/25'
var private_subnet_name = 'private'
var private_subnet_mask = '172.16.128.128/25'

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
          serviceEndpoints: []
          delegations: []
        }
      }
      {
        name: private_subnet_name
        properties: {
          addressPrefix: private_subnet_mask
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: [
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
                'westeurope'
              ]
            }
            {
              service: 'Microsoft.Storage'
              locations: [
                'westeurope'
                'northeurope'
              ]
            }
            {
              service: 'Microsoft.Web'
              locations: [
                '*'
              ]
            }
          ]
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
    virtualNetworkPeerings: []
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
