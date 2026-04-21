# Azure Application Gateway
resource "azurerm_resource_group" "appgw" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# Public IP for Application Gateway
resource "azurerm_public_ip" "appgw" {
  name                = "${var.appgw_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.domain_name_label

  tags = var.tags
}

# WAF Policy
resource "azurerm_web_application_firewall_policy" "waf" {
  count               = var.sku_tier == "WAF_v2" ? 1 : 0
  name                = "${var.appgw_name}-waf-policy"
  location            = var.location
  resource_group_name = var.resource_group_name

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

# Application Gateway
resource "azurerm_application_gateway" "main" {
  name                = var.appgw_name
  location            = var.location
  resource_group_name = var.resource_group_name
  firewall_policy_id  = var.sku_tier == "WAF_v2" ? azurerm_web_application_firewall_policy.waf[0].id : null

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    capacity = var.capacity
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  backend_address_pool {
    name         = var.backend_pool_name
    ip_addresses = var.backend_ip_addresses
  }

  backend_http_settings {
    name                  = "default-http-setting"
    cookie_based_affinity = "Disabled"
    port                  = var.backend_port
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "http-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = var.backend_pool_name
    backend_http_settings_name = "default-http-setting"
    priority                   = 100
  }
}
