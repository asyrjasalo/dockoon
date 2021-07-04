/*
------------------------------------------------------------------------------
PARAMETERS
------------------------------------------------------------------------------
*/

param dns_record_name string
param dns_zone_name string
param aci_ip_address string
param apim_ip_address string

param ttl_seconds int = 3600
param apim_record_name string = 'api'

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

resource apim 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  name: '${dns_zone_name}/${apim_record_name}'
  properties: {
    TTL: ttl_seconds
    ARecords: [
      {
        ipv4Address: apim_ip_address
      }
    ]
  }
}
