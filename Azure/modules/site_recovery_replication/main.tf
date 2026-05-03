resource "azurerm_site_recovery_fabric" "primary" {
  name                = "fabric-primary"
  resource_group_name = var.rg_secondary_name
  recovery_vault_name = var.recovery_vault_name
  location            = var.primary_location
}

resource "azurerm_site_recovery_fabric" "secondary" {
  name                = "fabric-secondary"
  resource_group_name = var.rg_secondary_name
  recovery_vault_name = var.recovery_vault_name
  location            = var.secondary_location
}

resource "azurerm_site_recovery_protection_container" "primary" {
  name                 = "protection-container-primary"
  resource_group_name  = var.rg_secondary_name
  recovery_vault_name  = var.recovery_vault_name
  recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
}

resource "azurerm_site_recovery_protection_container" "secondary" {
  name                 = "protection-container-secondary"
  resource_group_name  = var.rg_secondary_name
  recovery_vault_name  = var.recovery_vault_name
  recovery_fabric_name = azurerm_site_recovery_fabric.secondary.name
}

resource "azurerm_site_recovery_replication_policy" "policy" {
  name                                                 = "policy-vm"
  resource_group_name                                  = var.rg_secondary_name
  recovery_vault_name                                  = var.recovery_vault_name
  recovery_point_retention_in_minutes                  = 24 * 60
  application_consistent_snapshot_frequency_in_minutes = 4 * 60
}

resource "azurerm_site_recovery_protection_container_mapping" "container_mapping" {
  name                                      = "container-mapping"
  resource_group_name                       = var.rg_secondary_name
  recovery_vault_name                       = var.recovery_vault_name
  recovery_fabric_name                      = azurerm_site_recovery_fabric.primary.name
  recovery_source_protection_container_name = azurerm_site_recovery_protection_container.primary.name
  recovery_target_protection_container_id   = azurerm_site_recovery_protection_container.secondary.id
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.policy.id
}

resource "azurerm_site_recovery_network_mapping" "vnet_mapping" {
  name                        = "vnet-mapping"
  resource_group_name         = var.rg_secondary_name
  recovery_vault_name         = var.recovery_vault_name
  source_recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
  target_recovery_fabric_name = azurerm_site_recovery_fabric.secondary.name
  source_network_id           = var.vnet_primary_id
  target_network_id           = var.vnet_secondary_id
}

resource "azurerm_site_recovery_replicated_vm" "primary_vm_replica" {
  name                                      = "vm-replica-${var.workload_name}"
  resource_group_name                       = var.rg_secondary_name
  recovery_vault_name                       = var.recovery_vault_name
  source_recovery_fabric_name               = azurerm_site_recovery_fabric.primary.name
  source_vm_id                              = var.vm_id
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.policy.id
  source_recovery_protection_container_name = azurerm_site_recovery_protection_container.primary.name
  target_resource_group_id                  = var.rg_secondary_id
  target_recovery_fabric_id                 = azurerm_site_recovery_fabric.secondary.id
  target_recovery_protection_container_id   = azurerm_site_recovery_protection_container.secondary.id

  managed_disk {
    disk_id                    = var.vm_os_disk_id
    staging_storage_account_id = var.cache_storage_account_id
    target_resource_group_id   = var.rg_secondary_id
    target_disk_type           = "Premium_LRS"
    target_replica_disk_type   = "Premium_LRS"
  }

  network_interface {
    source_network_interface_id   = var.vm_nic_id
    target_subnet_name            = var.target_subnet_name
  }

  depends_on = [
    azurerm_site_recovery_protection_container_mapping.container_mapping,
    azurerm_site_recovery_network_mapping.vnet_mapping
  ]
}
