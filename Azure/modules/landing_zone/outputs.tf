output "resource_group_id" {
  description = "Resource Group ID"
  value       = azurerm_resource_group.workload.id
}

output "resource_group_name" {
  description = "Resource Group name"
  value       = azurerm_resource_group.workload.name
}

output "resource_group_location" {
  description = "Resource Group location"
  value       = azurerm_resource_group.workload.location
}

output "vnet_id" {
  description = "Virtual Network ID (if created)"
  value       = try(azurerm_virtual_network.workload[0].id, null)
}

output "vnet_name" {
  description = "Virtual Network name (if created)"
  value       = try(azurerm_virtual_network.workload[0].name, null)
}

output "vnet_cidr" {
  description = "Virtual Network address space (if created)"
  value       = var.use_hub_subnet ? null : azurerm_virtual_network.workload[0].address_space
}

output "subnet_id" {
  description = "Subnet ID"
  value       = var.use_hub_subnet ? data.azurerm_subnet.hub[0].id : try(azurerm_subnet.workload[0].id, null)
}

output "subnet_name" {
  description = "Subnet name"
  value       = var.use_hub_subnet ? data.azurerm_subnet.hub[0].name : try(azurerm_subnet.workload[0].name, null)
}

output "key_vault_id" {
  description = "Key Vault ID (if enabled)"
  value       = try(azurerm_key_vault.workload[0].id, null)
}

output "key_vault_name" {
  description = "Key Vault name (if enabled)"
  value       = try(azurerm_key_vault.workload[0].name, null)
}

output "key_vault_uri" {
  description = "Key Vault URI (if enabled)"
  value       = try(azurerm_key_vault.workload[0].vault_uri, null)
}

output "storage_account_id" {
  description = "Storage Account ID (if enabled)"
  value       = try(azurerm_storage_account.workload[0].id, null)
}

output "storage_account_name" {
  description = "Storage Account name (if enabled)"
  value       = try(azurerm_storage_account.workload[0].name, null)
}

output "storage_account_primary_blob_endpoint" {
  description = "Storage Account primary blob endpoint (if enabled)"
  value       = try(azurerm_storage_account.workload[0].primary_blob_endpoint, null)
}

output "storage_account_primary_access_key" {
  description = "Storage Account primary access key (if enabled)"
  value       = try(azurerm_storage_account.workload[0].primary_access_key, null)
  sensitive   = true
}
