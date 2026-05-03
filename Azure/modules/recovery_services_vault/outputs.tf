output "vault_id" {
  description = "Recovery Services Vault ID"
  value       = azurerm_recovery_services_vault.main.id
}

output "vault_name" {
  description = "Recovery Services Vault name"
  value       = azurerm_recovery_services_vault.main.name
}

output "vault_location" {
  description = "Recovery Services Vault location"
  value       = azurerm_recovery_services_vault.main.location
}

output "backup_policy_id" {
  description = "Backup Policy ID"
  value       = azurerm_backup_policy_vm.vm_backup.id
}

output "backup_policy_name" {
  description = "Backup Policy name"
  value       = azurerm_backup_policy_vm.vm_backup.name
}

output "backup_resource_group_name" {
  description = "Backup resource group name (if created)"
  value       = try(azurerm_resource_group.backup_rg[0].name, null)
}

output "identity_principal_id" {
  description = "The Principal ID of the System Assigned Identity for the Recovery Services Vault"
  value       = azurerm_recovery_services_vault.main.identity[0].principal_id
}
