output "storage_account_id" {
  description = "ID of the Terraform state storage account"
  value       = azurerm_storage_account.tfstate.id
}

output "storage_account_name" {
  description = "Name of the Terraform state storage account"
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Name of the Terraform state container"
  value       = azurerm_storage_container.tfstate.name
}

output "primary_blob_endpoint" {
  description = "Primary blob service endpoint"
  value       = azurerm_storage_account.tfstate.primary_blob_endpoint
}

output "storage_account_access_key" {
  description = "Primary access key for the storage account"
  value       = azurerm_storage_account.tfstate.primary_access_key
  sensitive   = true
}

output "network_default_action" {
  description = "Default network rule action"
  value       = azurerm_storage_account_network_rules.tfstate.default_action
}
