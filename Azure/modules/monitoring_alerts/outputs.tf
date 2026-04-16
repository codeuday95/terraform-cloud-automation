output "alert_rule_ids" {
  description = "Map of alert rule IDs"
  value = {
    high_cpu      = try(azurerm_monitor_scheduled_query_rule_alertv2.high_cpu.id, null)
    low_memory    = try(azurerm_monitor_scheduled_query_rule_alertv2.low_memory[0].id, null)
    low_disk      = try(azurerm_monitor_scheduled_query_rule_alertv2.low_disk[0].id, null)
    vm_deallocated = azurerm_monitor_scheduled_query_rule_alertv2.vm_deallocated.id
    high_network  = try(azurerm_monitor_scheduled_query_rule_alertv2.high_network_in.id, null)
  }
}

output "alert_names" {
  description = "Map of alert rule names"
  value = {
    high_cpu      = azurerm_monitor_scheduled_query_rule_alertv2.high_cpu.name
    low_memory    = try(azurerm_monitor_scheduled_query_rule_alertv2.low_memory[0].name, null)
    low_disk      = try(azurerm_monitor_scheduled_query_rule_alertv2.low_disk[0].name, null)
    vm_deallocated = azurerm_monitor_scheduled_query_rule_alertv2.vm_deallocated.name
    high_network  = try(azurerm_monitor_scheduled_query_rule_alertv2.high_network_in.name, null)
  }
}
