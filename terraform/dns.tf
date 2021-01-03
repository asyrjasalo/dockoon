resource "azurerm_dns_cname_record" "cname" {
  name                = "${var.app}.${var.environment}"
  resource_group_name = var.dns_zone_rg_name
  zone_name           = var.dns_zone_name
  ttl                 = 300 # seconds
  record              = azurerm_container_group.aci.fqdn

  tags = local.tags

  count = var.dns_zone_name != "" && var.visibility == "Public" ? 1 : 0
}


resource "azurerm_dns_a_record" "a" {
  name                = "${var.app}.${var.environment}"
  resource_group_name = var.dns_zone_rg_name
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records             = [azurerm_container_group.aci.ip_address]

  tags = local.tags

  count = var.dns_zone_name != "" ? 1 : 0
}
