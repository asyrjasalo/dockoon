/*
------------------------------------------------------------------------------
PARAMETERS
------------------------------------------------------------------------------
*/

param dns_record_name string
param dns_zone_name string
param aci_ip_address string
param apim_gateway_domain string
param apim_portal_domain string

param ttl_seconds int = 3600
param apim_gateway_record_name string = 'api'
param apim_portal_record_name string = 'portal'

/*
------------------------------------------------------------------------------
RESOURCES
------------------------------------------------------------------------------
*/

resource aci 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  name: '${dns_zone_name}/${dns_record_name}'
  properties: {
    TTL: ttl_seconds
    ARecords: [
      {
        ipv4Address: aci_ip_address
      }
    ]
  }
}

resource apim 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  name: '${dns_zone_name}/${apim_gateway_record_name}'
  properties: {
    TTL: ttl_seconds
    CNAMERecord: {
      cname: apim_gateway_domain
    }
  }
}

resource portal 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  name: '${dns_zone_name}/${apim_portal_record_name}'
  properties: {
    TTL: ttl_seconds
    CNAMERecord: {
      cname: apim_portal_domain
    }
  }
}

/*
------------------------------------------------------------------------------
OUTPUTS
------------------------------------------------------------------------------
*/

output aciBackendUrl string = aci.properties.fqdn
