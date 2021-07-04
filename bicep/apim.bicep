/*
------------------------------------------------------------------------------
PARAMETERS
------------------------------------------------------------------------------
*/

param apim_name string
param subnet_id string
param law_id string
param key_vault_name string
param key_vault_cert_name string
param dns_zone_name string
param uami_name string
param tags object

param apim_publisher_email string = 'devops@${dns_zone_name}'
param apim_publisher_name string = dns_zone_name
param apim_sku string = 'Developer'
param apim_capacity int = 1
param apim_gw_hostname string = 'api.${dns_zone_name}'
param apim_portal_hostname string = 'portal.${dns_zone_name}'
param apim_mgmt_hostname string = 'mgmt.${dns_zone_name}'

/*
------------------------------------------------------------------------------
EXISTING RESOURCES
------------------------------------------------------------------------------
*/

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: uami_name
}

/*
------------------------------------------------------------------------------
RESOURCES
------------------------------------------------------------------------------
*/

resource apim 'Microsoft.ApiManagement/service@2020-06-01-preview' = {
  name: apim_name
  location: resourceGroup().location
  tags: tags
  sku: {
    name: apim_sku
    capacity: apim_capacity
  }
  properties: {
    publisherEmail: apim_publisher_email
    publisherName: apim_publisher_name
    virtualNetworkConfiguration: {
      subnetResourceId: subnet_id
    }
    hostnameConfigurations: [
      {
        type: 'Proxy'
        hostName: apim_gw_hostname
        keyVaultId: 'https://${key_vault_name}.vault.azure.net/secrets/${key_vault_cert_name}'
        identityClientId: uami.properties.clientId
        negotiateClientCertificate: false
        defaultSslBinding: true
      }
      {
        type: 'DeveloperPortal'
        hostName: apim_portal_hostname
        keyVaultId: 'https://${key_vault_name}.vault.azure.net/secrets/${key_vault_cert_name}'
        identityClientId: uami.properties.clientId
        negotiateClientCertificate: false
        defaultSslBinding: false
      }
      {
        type: 'Management'
        hostName: apim_mgmt_hostname
        keyVaultId: 'https://${key_vault_name}.vault.azure.net/secrets/${key_vault_cert_name}'
        identityClientId: uami.properties.clientId
        negotiateClientCertificate: false
        defaultSslBinding: false
      }
    ]
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': 'True'
    }
    virtualNetworkType: 'External'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
}

resource diag 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'diag'
  scope: apim
  properties: {
    logAnalyticsDestinationType: 'Dedicated'
    workspaceId: law_id
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        timeGrain: 'PT1M'
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

/*
------------------------------------------------------------------------------
OUTPUTS
------------------------------------------------------------------------------
*/

output apiManagementId string = apim.id
output apiManagementVirtualIpAddress string = apim.properties.publicIPAddresses[0]
