# ACI

output "ip_address" {
  value = azurerm_container_group.aci.ip_address
}

output "fqdn" {
  value = azurerm_container_group.aci.fqdn
}

# DNS

output "cname" {
  value = var.dns_zone_name != "" ? azurerm_dns_cname_record.cname[0].fqdn : ""
}
