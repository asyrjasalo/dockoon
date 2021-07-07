/*
------------------------------------------------------------------------------
PARAMETERS
------------------------------------------------------------------------------
*/

param apim_name string
param apim_tier string
param apim_units int
param subnet_id string
param law_id string
param ai_name string
param key_vault_name string
param key_vault_cert_name string
param dns_zone_name string
param uami_name string
param tags object

param apim_publisher_email string = 'devops@${dns_zone_name}'
param apim_publisher_name string = dns_zone_name
param apim_network_type string = 'External'
param apim_gw_hostname string = 'api.${dns_zone_name}'
param apim_portal_hostname string = 'portal.${dns_zone_name}'
param apim_mgmt_hostname string = 'mgmt.${dns_zone_name}'
param apim_policy string = '''
<!--
    IMPORTANT:
    - Policy elements can appear only within the <inbound>, <outbound>, <backend> section elements.
    - Only the <forward-request> policy element can appear within the <backend> section element.
    - To apply a policy to the incoming request (before it is forwarded to the backend service), place a corresponding policy element within the <inbound> section element.
    - To apply a policy to the outgoing response (before it is sent back to the caller), place a corresponding policy element within the <outbound> section element.
    - To add a policy position the cursor at the desired insertion point and click on the round button associated with the policy.
    - To remove a policy, delete the corresponding policy statement from the policy document.
    - Policies are applied in the order of their appearance, from the top down.
-->
<policies>
    <inbound>
      <quota-by-key calls="1000"
                    bandwidth="100000"
                    renewal-period="86400"
                    counter-key="@(context.Request.IpAddress)" />
      <cors allow-credentials="true">
            <allowed-origins>
                <origin>https://{0}</origin>
            </allowed-origins>
            <allowed-methods preflight-result-max-age="300">
                <method>*</method>
            </allowed-methods>
            <allowed-headers>
                <header>*</header>
            </allowed-headers>
            <expose-headers>
                <header>*</header>
            </expose-headers>
        </cors>
    </inbound>
    <backend>
        <forward-request />
    </backend>
    <outbound />
    <on-error />
</policies>
'''

/*
------------------------------------------------------------------------------
EXISTING RESOURCES
------------------------------------------------------------------------------
*/

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: uami_name
}

resource ai 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: ai_name
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
    name: apim_tier
    capacity: apim_units
  }
  properties: {
    publisherName: apim_publisher_name
    publisherEmail: apim_publisher_email
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
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls1': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': 'True'
    }
    virtualNetworkType: apim_network_type
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
}

resource policy 'Microsoft.ApiManagement/service/policies@2020-06-01-preview' = {
  parent: apim
  name: 'policy'
  properties: {
    value: format(apim_policy, apim_portal_hostname)
    format: 'rawxml'
  }
}

resource logger 'Microsoft.ApiManagement/service/loggers@2019-01-01' = {
  parent: apim
  name: ai.name
  properties: {
    loggerType: 'applicationInsights'
    description: 'Logger resources to APIM'
    credentials: {
      instrumentationKey: ai.properties.InstrumentationKey
    }
    isBuffered: true
  }
}

resource loggerAi 'Microsoft.ApiManagement/service/diagnostics@2020-06-01-preview' = {
  parent: apim
  name: 'applicationinsights'
  properties: {
    loggerId: logger.id
    alwaysLog: 'allErrors'
    logClientIp: true
    sampling: {
      percentage: 100
      samplingType: 'fixed'
    }
  }
}

resource logLaw 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'log-to-law'
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

output apiManagementVirtualIpAddress string = apim.properties.publicIPAddresses[0]
output apiManagementGatewayFQDN string = apim.properties.gatewayUrl
output apiManagementPortalFQDN string = apim.properties.portalUrl
