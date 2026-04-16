output "bastion_id" {
  description = "Bastion Host ID"
  value       = azurerm_bastion_host.main.id
}

output "bastion_name" {
  description = "Bastion Host name"
  value       = azurerm_bastion_host.main.name
}

output "bastion_ip_address" {
  description = "Bastion Public IP address"
  value       = azurerm_public_ip.bastion.ip_address
}

output "bastion_public_ip_id" {
  description = "Bastion Public IP ID"
  value       = azurerm_public_ip.bastion.id
}

output "bastion_nsg_id" {
  description = "Bastion NSG ID (if created)"
  value       = try(azurerm_network_security_group.bastion[0].id, null)
}
