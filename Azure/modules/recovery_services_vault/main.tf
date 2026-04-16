# Recovery Services Vault and Backup Policy

resource "azurerm_recovery_services_vault" "main" {
  name                = var.vault_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku                      = var.sku
  soft_delete_enabled      = var.soft_delete_enabled
  soft_delete_retention_days = var.soft_delete_retention_days

  # Cross-region restore (for Geo-redundant storage)
  cross_region_restore_enabled = var.storage_redundancy == "GeoRedundant" ? true : false

  tags = var.tags
}

# Backup Policy for VMs
resource "azurerm_backup_policy_vm" "vm_backup" {
  name                = var.backup_policy_name
  resource_group_name = var.resource_group_name
  recovery_services_vault_name = azurerm_recovery_services_vault.main.name

  # Daily backup schedule
  backup_time         = var.backup_time  # Format: "HH:MM" in UTC
  timezone            = var.backup_timezone

  # Daily retention
  daily_retention_count   = var.daily_retention_days
  daily_retention_duration_in_days = var.daily_retention_days

  # Weekly retention
  weekly_retention_count  = var.weekly_retention_weeks
  weekly_retention_duration_in_days = var.weekly_retention_weeks * 7

  # Monthly retention (optional)
  monthly_retention_count = var.monthly_retention_months > 0 ? var.monthly_retention_months : null

  # Instant RP settings
  instant_rp_recovery_range_in_days = var.instant_rp_recovery_days
  instant_rp_enabled = var.instant_rp_enabled
}

# Backup Management Resource Group (optional, for storing backup data)
resource "azurerm_resource_group" "backup_rg" {
  count    = var.create_backup_resource_group ? 1 : 0
  name     = var.backup_resource_group_name
  location = var.location

  tags = var.tags
}
