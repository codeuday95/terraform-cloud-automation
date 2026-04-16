output "frontdoor_id" {
  description = "Front Door ID"
  value       = azurerm_frontdoor.main.id
}

output "frontdoor_name" {
  description = "Front Door name"
  value       = azurerm_frontdoor.main.name
}

output "frontdoor_endpoint" {
  description = "Front Door endpoint (FQDN)"
  value       = azurerm_frontdoor.main.frontend_endpoint[0].host_name
}

output "waf_policy_id" {
  description = "WAF Policy ID (if created)"
  value       = try(azurerm_frontdoor_firewall_policy.waf[0].id, null)
}

output "custom_domain_id" {
  description = "Custom Domain ID (if configured)"
  value       = try(azurerm_frontdoor_custom_domain.main[0].id, null)
}
