locals {
  aci_name = "${var.prefix}-${var.environment}-${var.app}-aci"
}

resource "azurerm_container_group" "aci" {
  name                = local.aci_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  dns_name_label  = "${var.container_name}-${var.environment}"
  ip_address_type = "Public"

  os_type        = "Linux"
  restart_policy = var.restart_policy

  container {
    name  = var.container_name
    image = var.docker_image

    commands                     = var.commands
    environment_variables        = var.environment_variables
    secure_environment_variables = var.secure_environment_variables

    cpu    = var.vcpu_count
    memory = var.memory_gbs

    dynamic "ports" {
      for_each = var.ports
      iterator = port

      content {
        port     = port.value
        protocol = "TCP"
      }
    }

    dynamic "volume" {
      for_each = var.volumes

      content {
        mount_path           = volume.value
        name                 = volume.key
        read_only            = true
        share_name           = volume.key
        storage_account_name = azurerm_storage_account.sa.name
        storage_account_key  = azurerm_storage_account.sa.primary_access_key
      }
    }
  }

  tags = local.tags
}
