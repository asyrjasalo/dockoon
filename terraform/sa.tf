locals {
  sa_name  = "${var.prefix}${var.environment}${var.app}sa"
}

resource "azurerm_storage_account" "sa" {
  name                     = local.sa_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = local.tags
}

resource "azurerm_storage_share" "shr" {
  for_each = var.volumes

  name                 = each.key
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 1 # GBs
}

resource "azurerm_management_lock" "lock" {
  name       = "cannotdelete"
  scope      = azurerm_storage_account.sa.id
  lock_level = "CanNotDelete"
  notes      = "Do not delete storage account"

  lifecycle {
    prevent_destroy = true
  }
}
