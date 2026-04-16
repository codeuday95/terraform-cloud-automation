output "vm_id" {
  description = "Linux VM ID"
  value       = azurerm_linux_virtual_machine.linux_vm.id
}

output "vm_name" {
  description = "Linux VM name"
  value       = azurerm_linux_virtual_machine.linux_vm.name
}

output "private_ip" {
  description = "Private IP address"
  value       = azurerm_network_interface.linux_vm.private_ip_address
}

output "public_ip" {
  description = "Public IP address"
  value       = var.enable_public_ip ? azurerm_public_ip.linux_vm[0].ip_address : null
}

output "nic_id" {
  description = "Network Interface ID"
  value       = azurerm_network_interface.linux_vm.id
}
