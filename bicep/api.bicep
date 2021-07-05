/*
------------------------------------------------------------------------------
PARAMETERS
------------------------------------------------------------------------------
*/

// APIM
param apim_name string

// Product
param app_name string
param app_description string = ' '
param app_terms string = ''
param app_require_admin_approval bool = true

// API
@allowed([
  'openapi'
  'openapi+json'
  'openapi+json-link'
  'swagger-json'
  'swagger-link-json'
  'wadl-link-json'
  'wadl-xml'
  'wsdl'
  'wsdl-link'
])
param api_format string = 'openapi+json-link'
param api_spec string
param api_backend_url string
param api_path string = app_name
param api_type string = 'http'
param api_description string = ' '
param api_set_current bool = true
param api_require_auth bool = true
param api_policy_xml string = '''
<policies>
    <inbound>
        <rate-limit calls="3" renewal-period="5" />
        <base />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
'''
param api_policy_format string = 'rawxml'

/*
------------------------------------------------------------------------------
VARIABLES
------------------------------------------------------------------------------
*/

var subscriptions_per_user_per_product = 1 // set to null to disable

/*
------------------------------------------------------------------------------
RESOURCES
------------------------------------------------------------------------------
*/

resource product 'Microsoft.ApiManagement/service/products@2020-06-01-preview' = {
  name: '${apim_name}/${app_name}'
  properties: {
    displayName: app_name
    description: app_description
    terms: app_terms
    subscriptionRequired: true
    approvalRequired: app_require_admin_approval
    subscriptionsLimit: subscriptions_per_user_per_product
    state: 'published'
  }
}

resource productGroups 'Microsoft.ApiManagement/service/products/groups@2020-06-01-preview' = {
  parent: product
  name: 'Developers'
}

resource api 'Microsoft.ApiManagement/service/apis@2020-06-01-preview' = {
  name: '${apim_name}/${api_path}'
  properties: {
    description: api_description
    serviceUrl: api_backend_url
    format: api_format
    value: api_spec
    path: api_path
    type: api_type
    apiType: api_type
    subscriptionRequired: api_require_auth
    isCurrent: api_set_current
    protocols: [
      'https'
    ]
  }
}

resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2019-01-01' = {
  parent: api
  name: 'policy'
  properties: {
    value: api_policy_xml
    format: api_policy_format
  }
}

resource apiToProduct 'Microsoft.ApiManagement/service/products/apis@2020-06-01-preview' = {
  parent: product
  name: api_path
}