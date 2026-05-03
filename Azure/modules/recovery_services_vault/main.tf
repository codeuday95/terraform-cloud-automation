# Recovery Services Vault and Backup Policy

resource "azurerm_recovery_services_vault" "main" {
  name                = var.vault_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku                      = var.sku
  
  # Cross-region restore (for Geo-redundant storage)
  cross_region_restore_enabled = var.storage_redundancy == "GeoRedundant" ? true : false

  identity {
    type = var.identity_type
  }

  tags = var.tags
}

# Backup Policy for VMs
resource "azurerm_backup_policy_vm" "vm_backup" {
  name                = var.backup_policy_name
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main.name
  timezone            = var.backup_timezone

  backup {
    frequency = "Daily"
    time      = var.backup_time
  }

  retention_daily {
    count = var.daily_retention_days
  }

  instant_restore_retention_days = var.instant_rp_recovery_days
}


# Backup Management Resource Group (optional, for storing backup data)
resource "azurerm_resource_group" "backup_rg" {
  count    = var.create_backup_resource_group ? 1 : 0
  name     = var.backup_resource_group_name
  location = var.location

  tags = var.tags
}
