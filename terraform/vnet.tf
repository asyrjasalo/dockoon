locals {
  vnet_name = "${var.prefix}-${var.environment}-${var.app}-vnet"
}

resource "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  address_space       = [var.vnet_address_space]
  dns_servers         = var.vnet_dns_servers

  tags = local.tags

  count = var.vnet_address_space != null ? 1 : 0
}

resource "azurerm_subnet" "public" {
  name                 = "public"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet[0].name
  address_prefixes     = [cidrsubnet(var.vnet_address_space, 2, 0)]

  # pick below
  service_endpoints = [
    #"Microsoft.AzureActiveDirectory",
    #"Microsoft.AzureCosmosDB",
    #"Microsoft.ContainerRegistry",
    #"Microsoft.EventHub", 
    #"Microsoft.KeyVault",
    #"Microsoft.ServiceBus",
    #"Microsoft.Sql",
    #"Microsoft.Storage",
    #"Microsoft.Web"
  ]
}

resource "azurerm_subnet" "private" {
  name                 = "private"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet[0].name
  address_prefixes     = [cidrsubnet(var.vnet_address_space, 2, 2)]

  delegation {
    name = "private"

    service_delegation {
      # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet#name
      name    = "Microsoft.ContainerInstance/containerGroups"

      # pick below
      actions = [
        "Microsoft.Network/networkinterfaces/*",
        "Microsoft.Network/virtualNetworks/subnets/action",
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}
