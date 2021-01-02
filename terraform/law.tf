locals {
  law_name = "${var.prefix}-${var.environment}-${var.app}-law"
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = local.law_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku                 = var.law_sku
  retention_in_days   = 30

  internet_ingestion_enabled = false # TODO: true?
  internet_query_enabled = false # TODO: true?

  tags = local.tags

  count = var.law_sku != null ? 1 : 0
}
