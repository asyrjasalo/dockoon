locals {
  aci_name  = "${var.prefix}-${var.environment}-${var.app}-aci"
  netp_name = "${var.prefix}-${var.environment}-${var.app}-netp"
  nic_name  = "${var.prefix}-${var.environment}-${var.app}-nic"
}

resource "azurerm_container_group" "aci" {
  name                = local.aci_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_address_type    = var.visibility
  dns_name_label     = var.visibility == "Public" ? "${var.container_name}-${var.environment}" : null
  network_profile_id = var.visibility == "Private" ? azurerm_network_profile.netp[0].id : null

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

  dynamic "diagnostics" {
    for_each = azurerm_log_analytics_workspace.law
    iterator = law

    content {
      log_analytics {
        log_type      = "ContainerInsights"
        workspace_id  = law.value != null ? law.value.workspace_id : null
        workspace_key = law.value != null ? law.value.primary_shared_key : null
      }
    }
  }

  tags = local.tags
}

resource "azurerm_network_profile" "netp" {
  name                = local.netp_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  container_network_interface {
    name = local.nic_name

    ip_configuration {
      name      = "private"
      subnet_id = azurerm_subnet.private.id
    }
  }

  tags = local.tags

  count = var.visibility == "Private" ? 1 : 0
}
