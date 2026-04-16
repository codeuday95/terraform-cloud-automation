# Azure Application Gateway with WAF v2

# Resource Group for App Gateway (optional, can use existing)
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

# Application Gateway
resource "azurerm_application_gateway" "main" {
  name                = var.appgw_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = var.sku_name       # Standard_v2 or WAF_v2
    tier     = var.sku_tier       # Standard_v2 or WAF_v2
    capacity = var.capacity       # 1-125 instances
  }

  # Gateway IP Configuration
  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.subnet_id
  }

  # Frontend IP Configuration
  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  # Frontend Port - HTTP
  frontend_port {
    name = "http-port"
    port = 80
  }

  # Frontend Port - HTTPS
  frontend_port {
    name = "https-port"
    port = 443
  }

  # Backend Address Pool
  backend_address_pool {
    name  = var.backend_pool_name
    ip_addresses = var.backend_ip_addresses
    fqdns         = var.backend_fqdns
  }

  # Backend HTTP Settings
  backend_http_settings {
    name                  = "default-http-setting"
    cookie_based_affinity = "Disabled"
    port                  = var.backend_port
    protocol              = "Http"
    request_timeout       = 60

    dynamic "probe" {
      for_each = var.enable_probe ? [1] : []
      content {
        name = "health-probe"
      }
    }
  }

  # HTTP Listener
  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  # HTTPS Listener (if certificate provided)
  dynamic "http_listener" {
    for_each = var.enable_https ? [1] : []
    content {
      name                           = "https-listener"
      frontend_ip_configuration_name = "frontend-ip"
      frontend_port_name             = "https-port"
      protocol                       = "Https"
      ssl_certificate_name          = var.ssl_cert_name
      host_names                    = var.host_names
    }
  }

  # Routing Rule
  request_routing_rule {
    name                       = "default-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = var.backend_pool_name
    backend_http_settings_name = "default-http-setting"
    priority                   = 100
  }

  # WAF Configuration (if WAF_v2 SKU)
  dynamic "waf_configuration" {
    for_each = var.enable_waf ? [1] : []
    content {
      enabled                  = true
      firewall_mode            = var.waf_mode           # Prevention or Detection
      rule_set_type            = var.waf_rule_set_type  # OWASP
      rule_set_version         = var.waf_rule_set_version
      file_upload_limit_mb     = var.waf_file_upload_limit
      max_body_size_kb         = var.waf_max_body_size
      inspection_limit_mib     = var.waf_inspection_limit
    }
  }

  # Autoscale Configuration
  dynamic "autoscale_configuration" {
    for_each = var.enable_autoscale ? [1] : []
    content {
      min_capacity = var.autoscale_min_capacity
      max_capacity = var.autoscale_max_capacity
    }
  }

  tags = var.tags

  depends_on = [
    azurerm_resource_group.appgw
  ]
}

# Web Application Firewall (WAF) Policy
resource "azurerm_web_application_firewall_policy" "waf" {
  count               = var.enable_waf_policy ? 1 : 0
  name                = "${var.appgw_name}-waf-policy"
  location            = var.location
  resource_group_name = var.resource_group_name

  enabled                         = true
  mode                            = var.waf_mode  # Prevention or Detection

  # OWASP Rule Set
  policy_settings {
    enabled                     = true
    mode                        = var.waf_mode
    request_body_check          = true
    max_request_body_size_in_kb = var.waf_max_body_size
    file_upload_limit_in_mb     = var.waf_file_upload_limit
  }

  # Custom Rules (optional)
  dynamic "custom_rule" {
    for_each = var.waf_custom_rules
    content {
      name      = custom_rule.value.name
      priority  = custom_rule.value.priority
      rule_type = custom_rule.value.rule_type
      action    = custom_rule.value.action
      match_conditions {
        match_variables {
          variable_name = custom_rule.value.match_variable
        }
        operator           = custom_rule.value.operator
        negation_condition = false
        match_values       = custom_rule.value.match_values
      }
    }
  }

  tags = var.tags
}

# Health Probe (optional)
resource "azurerm_application_gateway" "probe" {
  count = var.enable_probe ? 1 : 0
  # Probes are defined inline in Application Gateway
  # This is a placeholder for complex probe scenarios
}
