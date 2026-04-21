data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = var.frontdoor_name
  resource_group_name = data.azurerm_resource_group.rg.name
  sku_name            = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = var.frontdoor_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

resource "azurerm_cdn_frontdoor_origin_group" "main" {
  name                     = "default-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  session_affinity_enabled = false
  load_balancing {
    additional_latency_in_milliseconds = 50
    sample_size                        = 4
    successful_samples_required        = 3
  }
  health_probe {
    interval_in_seconds = var.health_probe_interval
    path                = var.health_probe_path
    protocol            = var.health_probe_protocol == "Https" ? "Https" : "Http"
    request_type        = "HEAD"
  }
}

resource "azurerm_cdn_frontdoor_origin" "primary" {
  name                           = "primary-backend"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.main.id
  enabled                        = true
  certificate_name_check_enabled = false
  host_name                      = var.primary_backend_address
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = var.primary_backend_address
  priority                       = 1
  weight                         = 1000
}

resource "azurerm_cdn_frontdoor_origin" "secondary" {
  for_each = { for idx, backend in var.secondary_backends : backend.name => backend }
  name                           = each.key
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.main.id
  enabled                        = true
  certificate_name_check_enabled = false
  host_name                      = each.value.address
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = each.value.address
  priority                       = 2
  weight                         = 1000
}

resource "azurerm_cdn_frontdoor_route" "main" {
  name                          = "default-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id
  cdn_frontdoor_origin_ids      = concat([azurerm_cdn_frontdoor_origin.primary.id], [for o in azurerm_cdn_frontdoor_origin.secondary : o.id])
  supported_protocols           = ["Http", "Https"]
  patterns_to_match             = ["/*"]
  forwarding_protocol           = "MatchRequest"
  https_redirect_enabled        = true
}

resource "azurerm_cdn_frontdoor_firewall_policy" "waf" {
  name                = replace(var.frontdoor_name, "-", "")
  resource_group_name = data.azurerm_resource_group.rg.name
  sku_name            = "Standard_AzureFrontDoor"
  mode                = "Prevention"
}
