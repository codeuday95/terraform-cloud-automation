output "diagnostic_setting_id" {
  description = "Diagnostic Setting ID"
  value       = azurerm_monitor_diagnostic_setting.vm_diagnostics.id
}

output "boot_diagnostics_id" {
  description = "Boot Diagnostics Setting ID"
  value       = azurerm_monitor_diagnostic_setting.boot_diagnostics.id
}

output "data_collection_rule_id" {
  description = "Data Collection Rule ID (if enabled)"
  value       = try(azurerm_monitor_data_collection_rule.vm_logs[0].id, null)
}

output "data_collection_rule_association_id" {
  description = "DCR Association ID (if enabled)"
  value       = try(azurerm_monitor_data_collection_rule_association.vm_association[0].id, null)
}
