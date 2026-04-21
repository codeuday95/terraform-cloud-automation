output "frontdoor_id" {
  description = "Front Door ID"
  value       = azurerm_cdn_frontdoor_profile.main.id
}

output "frontdoor_name" {
  description = "Front Door Name"
  value       = azurerm_cdn_frontdoor_profile.main.name
}

output "frontdoor_endpoint" {
  description = "Front Door Endpoint Hostname"
  value       = azurerm_cdn_frontdoor_endpoint.main.host_name
}
