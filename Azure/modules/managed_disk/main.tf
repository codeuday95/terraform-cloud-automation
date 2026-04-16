# Managed Disk for VM
resource "azurerm_managed_disk" "vm_os" {
  name                 = var.disk_name
  location             = var.location
  resource_group_name  = var.resource_group_name
  create_option        = "FromImage"
  os_type              = var.os_type
  disk_size_gb         = var.disk_size_gb
  storage_account_type = var.storage_account_type

  tags = var.tags
}
