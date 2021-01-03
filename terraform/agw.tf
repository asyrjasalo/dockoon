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

  count = var.enable_appgw ? 1 : 0
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

  gateway_ip_configuration {
    name      = azurerm_subnet.public.name
    subnet_id = azurerm_subnet.public.id
  }

  backend_address_pool {
    name         = "${var.container_name}-${var.environment}"
    ip_addresses = [azurerm_container_group.aci.ip_address]
  }

  backend_http_settings {
    name                                = local.aci_name
    cookie_based_affinity               = "Disabled"
    port                                = 8080
    protocol                            = "Http"
    probe_name                          = "healthcheck"
    request_timeout                     = 60
    pick_host_name_from_backend_address = true
  }

  probe {
    name                                      = "healthcheck"
    protocol                                  = "Http"
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  frontend_ip_configuration {
    name                 = "public-ip"
    public_ip_address_id = azurerm_public_ip.pip[0].id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  http_listener {
    name                           = "listen-http"
    frontend_ip_configuration_name = "public-ip"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "request-http"
    rule_type                  = "Basic"
    http_listener_name         = "listen-http"
    backend_address_pool_name  = "${var.container_name}-${var.environment}"
    backend_http_settings_name = local.aci_name
  }

  frontend_port {
    name = "https"
    port = 443
  }

  http_listener {
    name                           = "listen-https"
    frontend_ip_configuration_name = "public-ip"
    frontend_port_name             = "https"
    protocol                       = "Https"
    ssl_certificate_name           = "cert"
  }

  ssl_certificate {
    name     = "cert"
    data     = filebase64(var.cert_pfx_path)
    password = var.cert_password
  }

  request_routing_rule {
    name                       = "request-https"
    rule_type                  = "Basic"
    http_listener_name         = "listen-https"
    backend_address_pool_name  = "${var.container_name}-${var.environment}"
    backend_http_settings_name = local.aci_name
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S" # TLSv1_2 min requirement
  }

  count = var.enable_appgw ? 1 : 0
}
