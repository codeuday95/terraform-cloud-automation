output "budget_id" {
  description = "Budget ID"
  value       = azurerm_consumption_budget.workload_budget.id
}

output "budget_name" {
  description = "Budget name"
  value       = azurerm_consumption_budget.workload_budget.name
}

output "action_group_id" {
  description = "Action Group ID (if created)"
  value       = try(azurerm_monitor_action_group.budget_alerts[0].id, null)
}
