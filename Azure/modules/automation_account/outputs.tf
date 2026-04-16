output "automation_account_id" {
  description = "Automation Account ID"
  value       = azurerm_automation_account.main.id
}

output "automation_account_name" {
  description = "Automation Account name"
  value       = azurerm_automation_account.main.name
}

output "managed_identity_principal_id" {
  description = "Managed Identity Principal ID"
  value       = azurerm_automation_account.main.identity[0].principal_id
}
