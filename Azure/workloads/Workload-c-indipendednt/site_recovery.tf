# =============================================================================
# Azure Site Recovery Vault & Configuration
# =============================================================================

module "asr_vault" {
  source              = "../../modules/recovery_services_vault"
  vault_name          = "rsv-${var.workload_name}-${var.secondary_location}"
  location            = module.rg_secondary.location
  resource_group_name = module.rg_secondary.name
  tags                = var.tags
}

module "asr_cache_storage" {
  source              = "../../modules/storage_account"
  name                = "stcache${var.workload_name}${random_string.global.result}"
  resource_group_name = module.rg_primary.name
  location            = module.rg_primary.location
  account_tier        = "Standard"
  account_replication_type = "LRS"
  tags                = var.tags
}

resource "azurerm_role_assignment" "asr_storage_blob_contributor" {
  scope                = module.asr_cache_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.asr_vault.identity_principal_id
}

resource "azurerm_role_assignment" "asr_storage_account_contributor" {
  scope                = module.asr_cache_storage.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = module.asr_vault.identity_principal_id
}

module "asr_replication" {
  source                   = "../../modules/site_recovery_replication"
  workload_name            = var.workload_name
  primary_location         = module.rg_primary.location
  secondary_location       = module.rg_secondary.location
  rg_primary_name          = module.rg_primary.name
  rg_secondary_name        = module.rg_secondary.name
  rg_secondary_id          = module.rg_secondary.id
  recovery_vault_name      = module.asr_vault.vault_name
  vnet_primary_id          = module.vnet_primary.vnet_id
  vnet_secondary_id        = module.vnet_secondary.vnet_id
  cache_storage_account_id = module.asr_cache_storage.id
  vm_id                    = module.vm_primary.vm_id
  vm_os_disk_id            = module.vm_primary.os_disk_id
  vm_nic_id                = module.vm_primary.nic_id
  target_subnet_name       = "snet-web"

  depends_on = [
    azurerm_role_assignment.asr_storage_blob_contributor,
    azurerm_role_assignment.asr_storage_account_contributor
  ]
}
