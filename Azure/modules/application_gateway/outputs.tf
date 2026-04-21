output "appgw_id" {
  description = "Application Gateway ID"
  value       = azurerm_application_gateway.main.id
}

output "appgw_name" {
  description = "Application Gateway name"
  value       = azurerm_application_gateway.main.name
}

output "appgw_public_ip" {
  description = "Application Gateway Public IP"
  value       = azurerm_public_ip.appgw.ip_address
}

output "appgw_public_ip_id" {
  description = "Application Gateway Public IP ID"
  value       = azurerm_public_ip.appgw.id
}

output "waf_policy_id" {
  description = "WAF Policy ID (if created)"
  value       = try(azurerm_web_application_firewall_policy.waf[0].id, null)
}

