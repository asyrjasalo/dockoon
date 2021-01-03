locals {
  agw_name = "${var.prefix}-${var.environment}-${var.app}-agw"
  pip_name = "${var.prefix}-${var.environment}-${var.app}-pip"
}

resource "azurerm_public_ip" "pip" {
  name                = local.pip_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  allocation_method = "Dynamic"

  tags = local.tags
}

resource "azurerm_application_gateway" "agw" {
  name                = local.agw_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  enable_http2 = true

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 1
  }

  backend_address_pool {
    name         = "${var.container_name}-${var.environment}"
    ip_addresses = [azurerm_container_group.aci.ip_address]
  }

  backend_http_settings {
    name                  = "Http"
    cookie_based_affinity = "Disabled"
    port                  = 8080
    protocol              = "Http"
    request_timeout       = 60
  }

  frontend_ip_configuration {
    name                 = "public-ip"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  frontend_ip_configuration {
    name      = "private-ip"
    subnet_id = azurerm_subnet.public.id
  }

  frontend_port {
    name = "public"
    port = 80
  }

  frontend_port {
    name = "private"
    port = 8080
  }

  gateway_ip_configuration {
    name      = azurerm_subnet.public.name
    subnet_id = azurerm_subnet.public.id
  }

  http_listener {
    name                           = "public-http"
    frontend_ip_configuration_name = "public-ip"
    frontend_port_name             = "public"
    protocol                       = "Http"
  }

  http_listener {
    name                           = "private-http"
    frontend_ip_configuration_name = "private-ip"
    frontend_port_name             = "private"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "request-public-http"
    rule_type                  = "Basic"
    http_listener_name         = "public-http"
    backend_address_pool_name  = "${var.container_name}-${var.environment}"
    backend_http_settings_name = "Http"
  }

  # TODO: requires SSL certificate
  /*
  request_routing_rule {
    name                       = "request-public-https"
    rule_type                  = "Basic"
    http_listener_name         = "public-https"
    backend_address_pool_name  = "${var.container_name}-${var.environment}"
    backend_http_settings_name = "Https"
  }

  ssl_policy {
    policy_type = "Custom"
    min_protocol_version = "TLSv1_2"
  }
  */
}