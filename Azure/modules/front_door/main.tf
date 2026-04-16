# Azure Front Door (Standard/Premium)

# Profile for Front Door
resource "azurerm_frontdoor" "main" {
  name                = var.frontdoor_name
  resource_group_name = var.resource_group_name
  location            = "global"  # Front Door is global

  routing_rule {
    name                          = "default-routing-rule"
    forwarding_protocol           = "MatchRequest"
    patterns_to_match             = ["/*"]
    frontend_endpoints            = ["frontend-endpoint"]
    enabled                       = true
    backend_pool_name             = "default-backend-pool"
  }

  frontend_endpoint {
    name                              = "frontend-endpoint"
    host_name                         = "${var.frontdoor_name}.azurefd.net"
    session_affinity_enabled          = var.session_affinity_enabled
    session_affinity_ttl_seconds      = var.session_affinity_ttl
    web_application_firewall_policy_id = var.enable_waf ? azurerm_frontdoor_firewall_policy.waf[0].id : null
  }

  backend_pool {
    name = "default-backend-pool"
    backend {
      name    = "primary-backend"
      address = var.primary_backend_address
      enabled = true
    }
    dynamic "backend" {
      for_each = var.secondary_backends
      content {
        name    = backend.value.name
        address = backend.value.address
        enabled = true
      }
    }
    load_balancing_name = "default-load-balancing"
    health_probe_name   = "default-health-probe"
  }

  load_balancing {
    name                        = "default-load-balancing"
    successful_samples_required = 2
  }

  health_probe {
    name                = "default-health-probe"
    interval_in_seconds = var.health_probe_interval
    path                = var.health_probe_path
    protocol            = var.health_probe_protocol
  }

  tags = var.tags
}

# WAF Policy for Front Door
resource "azurerm_frontdoor_firewall_policy" "waf" {
  count               = var.enable_waf ? 1 : 0
  name                = "${var.frontdoor_name}-waf-policy"
  resource_group_name = var.resource_group_name
  location            = "global"  # Front Door WAF is global

  enabled                         = true
  mode                            = var.waf_mode  # Prevention or Detection

  # OWASP Rule Set
  custom_rule {
    name           = "block-ip-rule"
    enabled        = true
    priority       = 1
    rule_type      = "MatchRule"
    action         = "Block"
    match_condition {
      match_variable    = "RemoteAddr"
      operator          = "IPMatch"
      negation_condition = false
      match_values      = var.waf_blocked_ips
      transforms        = []
    }
  }

  # OWASP 3.2 configuration
  policy_settings {
    enabled                     = true
    mode                        = var.waf_mode
    request_body_check          = true
    max_request_body_size_in_kb = 32
  }

  tags = var.tags
}

# Custom Domain Configuration (optional, requires certificate)
resource "azurerm_frontdoor_custom_domain" "main" {
  count = var.enable_custom_domain ? 1 : 0

  name                     = var.custom_domain_name
  frontdoor_id             = azurerm_frontdoor.main.id
  host_name                = var.custom_domain_hostname
  frontend_endpoint_name   = "frontend-endpoint"

  https {
    certificate_type    = var.certificate_type  # FrontDoor or Customer
    secret              = var.certificate_secret_id
    protocol_type       = var.tls_protocol_type
    minimum_tls_version = var.minimum_tls_version
  }
}

# Route for traffic routing
resource "azurerm_frontdoor_route" "main" {
  name                            = "${var.frontdoor_name}-route"
  frontdoor_id                    = azurerm_frontdoor.main.id
  frontend_endpoint_name          = "frontend-endpoint"
  patterns_to_match               = var.route_patterns_to_match
  protocols_enabled               = var.route_protocols_enabled
  cache_enabled                   = var.route_cache_enabled
  forwarding_protocol             = var.route_forwarding_protocol
  backend_pool_name               = "default-backend-pool"
  enabled                         = true
}
