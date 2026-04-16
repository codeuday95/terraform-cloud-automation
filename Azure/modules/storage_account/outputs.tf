output "id" {
  description = "Storage Account ID"
  value       = azurerm_storage_account.sa.id
}

output "name" {
  description = "Storage Account name"
  value       = azurerm_storage_account.sa.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.sa.primary_blob_endpoint
}
