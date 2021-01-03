# ACI

output "acr_ip" {
  value = azurerm_container_group.aci.ip_address
}

output "acr_fqdn" {
  value = azurerm_container_group.aci.fqdn
}

# DNS

output "dns_aci_cname" {
  value = var.dns_zone_name != "" && var.visibility == "Public" ? azurerm_dns_cname_record.cname[0].fqdn : null
}

output "dns_aci_a" {
  value = var.dns_zone_name != "" && var.visibility == "Private" ? azurerm_dns_a_record.a[0].fqdn : null
}

# AppGw public IP

output "dns_agw_cname" {
  value = var.dns_zone_name != "" && var.enable_appgw ? azurerm_dns_a_record.pip[0].fqdn : null
}
