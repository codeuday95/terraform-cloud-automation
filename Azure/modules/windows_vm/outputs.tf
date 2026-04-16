output "vm_id" {
  description = "VM ID"
  value       = azurerm_windows_virtual_machine.vm.id
}

output "vm_name" {
  description = "VM name"
  value       = azurerm_windows_virtual_machine.vm.name
}

output "private_ip_address" {
  description = "Private IP address"
  value       = module.nic.private_ip_address
}

output "public_ip_address" {
  description = "Public IP address (if enabled)"
  value       = module.nic.public_ip_address
}

output "admin_username" {
  description = "Admin username"
  value       = var.admin_username
  sensitive   = true
}

output "admin_password_secret_name" {
  description = "Key Vault secret name for admin password"
  value       = "${var.vm_name}-admin-password"
}

output "nsg_id" {
  description = "Network Security Group ID"
  value       = module.nsg.id
}
