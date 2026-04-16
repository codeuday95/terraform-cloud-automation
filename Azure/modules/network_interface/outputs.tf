output "id" {
  description = "NIC ID"
  value       = azurerm_network_interface.vm.id
}

output "name" {
  description = "NIC name"
  value       = azurerm_network_interface.vm.name
}

output "private_ip_address" {
  description = "Private IP address"
  value       = azurerm_network_interface.vm.private_ip_address
}

output "public_ip_address" {
  description = "Public IP address (if enabled)"
  value       = try(azurerm_public_ip.vm[0].ip_address, null)
}
