output "id" {
  description = "NSG ID"
  value       = azurerm_network_security_group.vm.id
}

output "name" {
  description = "NSG name"
  value       = azurerm_network_security_group.vm.name
}
