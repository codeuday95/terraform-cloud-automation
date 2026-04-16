output "id" {
  description = "Managed Disk ID"
  value       = azurerm_managed_disk.vm_os.id
}

output "name" {
  description = "Managed Disk name"
  value       = azurerm_managed_disk.vm_os.name
}
