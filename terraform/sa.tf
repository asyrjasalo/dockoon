locals {
  sa_name = "${var.prefix}${var.environment}${var.app}sa"
}

resource "azurerm_storage_account" "sa" {
  # checkov:skip=CKV_AZURE_35:[TODO] Restrict network to one's IP and VNET
  # checkov:skip=CKV_AZURE_43:[WONTFIX] Using different naming convention
  name                = local.sa_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"

  # checkov:skip=CKV_AZURE_33:[INVALID] Storage queue is not used here
  /*queue_properties  {
    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 7
    }
  }*/

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
