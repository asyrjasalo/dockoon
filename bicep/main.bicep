/*
------------------------------------------------------------------------------
PARAMETERS
------------------------------------------------------------------------------
*/

@description('Prefix')
@minLength(2)
@maxLength(4)
param prefix string

@description('App name')
@minLength(2)
@maxLength(10)
param app string = 'dockoon'

@description('Environment')
@allowed([
  'test'
  'stg'
  'prod'
])
param environment string = 'test'

@description('Owner')
@minLength(2)
@maxLength(32)
param owner string

@description('Existing DNS zone name in the subscription for records')
param dns_zone_name string

@description('Resource group of the DNS zone')
param dns_zone_rg_name string

@description('Existing key vault name having the certificates')
param key_vault_name string

@description('Resource group of the key vault')
param key_vault_rg_name string

@description('Certificate name for the wildcard cert stored in the key vault')
param key_vault_cert_name string

/*
------------------------------------------------------------------------------
VARIABLES
------------------------------------------------------------------------------
*/

var tags = {
  app: app
  environment: environment
  owner: owner
}

var uami_name = '${prefix}-${environment}-${app}-uami'
var vnet_name = '${prefix}-${environment}-${app}-vnet'
var sa_name = '${prefix}${environment}${app}sa'
var aci_name = '${prefix}-${environment}-${app}-aci'
var aci_nic_name = '${prefix}-${environment}-${app}-nic'
var law_name = '${prefix}-${environment}-${app}-law'
var ai_name = '${prefix}-${environment}-${app}-ai'
var apim_name = '${prefix}-${environment}-${app}-apim'
var dns_record_name = '${app}-${environment}'

/*
------------------------------------------------------------------------------
MODULES
------------------------------------------------------------------------------
*/

// Virtual Network

module vnet './vnet.bicep' = {
  name: 'vnet'
  params: {
    vnet_name: vnet_name
    tags: tags
  }
}

var public_subnet_id = vnet.outputs.publicSubnetResourceId
var private_subnet_id = vnet.outputs.privateSubnetResourceId

// Storage Account

module sa './sa.bicep' = {
  name: 'sa'
  params: {
    sa_name: sa_name
    tags: tags
  }
}

// Azure Container Instances

module aci './aci.bicep' = {
  name: 'aci'
  params: {
    aci_name: aci_name
    aci_nic_name: aci_nic_name
    aci_subnet_id: private_subnet_id
    sa_name: sa_name
    tags: tags
  }
}
var aci_ip_address = aci.outputs.aciIpAddress

// Log Analytics Workspace

module law './law.bicep' = {
  name: 'law'
  params: {
    law_name: law_name
    tags: tags
  }
}

var law_id = law.outputs.logAnalyticsWorkspaceId

// Application Insights

module ai './ai.bicep' = {
  name: 'ai'
  params: {
    ai_name: ai_name
    law_id: law_id
    tags: tags
  }
}

// User Assigned Managed Identity

module uami './uami.bicep' = {
  name: 'uami'
  params: {
    uami_name: uami_name
    tags: tags
  }
}

var uami_principal_id = uami.outputs.principalId

// Key Vault

module kv './kv.bicep' = {
  name: 'kv'
  params: {
    key_vault_name: key_vault_name
    uami_object_id: uami_principal_id
  }
  scope: resourceGroup(key_vault_rg_name)
}

// API Management

module apim './apim.bicep' = {
  name: 'apim'
  params: {
    apim_name: apim_name
    subnet_id: public_subnet_id
    law_id: law_id
    ai_name: ai_name
    dns_zone_name: dns_zone_name
    key_vault_name: key_vault_name
    key_vault_cert_name: key_vault_cert_name
    uami_name: uami_name
    tags: tags
  }
}

// DNS

module dns './dns.bicep' = {
  name: 'dns'
  params: {
    dns_zone_name: dns_zone_name
    dns_record_name: dns_record_name
    aci_ip_address: aci_ip_address
    apim_gateway_domain: '${apim_name}.azure-api.net'
    apim_portal_domain: '${apim_name}.portal.azure-api.net'
    apim_mgmt_domain: '${apim_name}.mgmt.azure-api.net'
  }
  scope: resourceGroup(dns_zone_rg_name)
}

// API in APIM

module api './api.bicep' = {
  name: 'api'
  params: {
    app_name: app
    apim_name: apim_name
    api_spec_url: 'https://${sa_name}.blob.core.windows.net/apis/openapi.json'
    api_backend_url: 'http://${aci_ip_address}:8080'
  }
}
