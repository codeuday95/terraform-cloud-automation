output "front_door_url" {
  description = "Global Front Door Endpoint URL"
  value       = "https://${module.front_door.frontdoor_endpoint}"
}

output "primary_appgw_ip" {
  description = "Primary Application Gateway Public IP"
  value       = module.appgw_primary.appgw_public_ip
}

output "secondary_appgw_ip" {
  description = "Secondary Application Gateway Public IP"
  value       = module.appgw_secondary.appgw_public_ip
}

output "sql_auto_failover_fqdn" {
  description = "SQL Server Auto-Failover Endpoint"
  value       = azurerm_mssql_failover_group.fog.id
}

output "key_vault_name" {
  description = "Key Vault containing all generated passwords"
  value       = module.key_vault.name
}
