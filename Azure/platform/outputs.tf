# =============================================================================
# Platform Outputs
# =============================================================================

output "platform_rg_id" {
  description = "Platform Resource Group ID"
  value       = data.azurerm_resource_group.platform.id
}

output "platform_rg_name" {
  description = "Platform Resource Group name"
  value       = data.azurerm_resource_group.platform.name
}

output "hub_vnet_id" {
  description = "Hub Virtual Network ID"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Hub Virtual Network name"
  value       = azurerm_virtual_network.hub.name
}

output "hub_subnets" {
  description = "Hub Subnets map"
  value = {
    for subnet in azurerm_subnet.hub_subnets :
    subnet.name => {
      id               = subnet.id
      address_prefixes = subnet.address_prefixes
    }
  }
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.platform.id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics Workspace name"
  value       = azurerm_log_analytics_workspace.platform.name
}

output "platform_keyvault_id" {
  description = "Platform Key Vault ID"
  value       = azurerm_key_vault.platform.id
}

output "platform_keyvault_name" {
  description = "Platform Key Vault name"
  value       = azurerm_key_vault.platform.name
}

# =============================================================================
# Landing Zone Outputs (aggregated from modules)
# =============================================================================

output "landing_zones" {
  description = "Landing Zones created for each workload"
  value = {
    for name, lz in module.landing_zone :
    name => {
      resource_group_id             = lz.resource_group_id
      resource_group_name           = lz.resource_group_name
      resource_group_location       = lz.resource_group_location
      vnet_id                       = lz.vnet_id
      vnet_name                     = lz.vnet_name
      subnet_id                     = lz.subnet_id
      subnet_name                   = lz.subnet_name
      key_vault_id                  = lz.key_vault_id
      key_vault_name                = lz.key_vault_name
      key_vault_uri                 = lz.key_vault_uri
      storage_account_id            = lz.storage_account_id
      storage_account_name          = lz.storage_account_name
      storage_account_blob_endpoint = lz.storage_account_primary_blob_endpoint
    }
  }
}

output "workload_resource_groups" {
  description = "Workload Resource Groups (from landing zones)"
  value = {
    for name, lz in module.landing_zone :
    name => {
      id   = lz.resource_group_id
      name = lz.resource_group_name
    }
  }
}

output "workload_keyvaults" {
  description = "Workload Key Vaults (from landing zones)"
  value = {
    for name, lz in module.landing_zone :
    name => {
      id   = lz.key_vault_id
      name = lz.key_vault_name
    }
  }
}

output "workload_storage_accounts" {
  description = "Workload Storage Accounts (from landing zones)"
  value = {
    for name, lz in module.landing_zone :
    name => {
      id                    = lz.storage_account_id
      name                  = lz.storage_account_name
      primary_blob_endpoint = lz.storage_account_primary_blob_endpoint
      primary_access_key    = lz.storage_account_primary_access_key
    }
  }
  sensitive = true
}

output "workload_subnets" {
  description = "Workload Subnets (from landing zones)"
  value = {
    for name, lz in module.landing_zone :
    name => {
      id   = lz.subnet_id
      name = lz.subnet_name
    }
  }
}

# =============================================================================
# Service Principal Outputs
# =============================================================================

output "platform_sp" {
  description = "Platform Service Principal details"
  value = {
    display_name = azuread_application.platform.display_name
    client_id    = azuread_application.platform.client_id
    object_id    = azuread_service_principal.platform.object_id
    tenant_id    = data.azuread_client_config.current.tenant_id
  }
  sensitive = true
}

output "workload_sps" {
  description = "Workload Service Principals details"
  value = {
    for workload in var.workloads :
    workload.name => {
      display_name = azuread_application.workload[workload.name].display_name
      client_id    = azuread_application.workload[workload.name].client_id
      object_id    = azuread_service_principal.workload[workload.name].object_id
      tenant_id    = data.azuread_client_config.current.tenant_id
    }
  }
  sensitive = true
}

# =============================================================================
# RBAC Groups Outputs
# =============================================================================

output "rbac_groups" {
  description = "RBAC Groups created for platform and workloads"
  value = {
    platform = {
      admins  = azuread_group.platform_admins.id
      users   = azuread_group.platform_users.id
      readers = azuread_group.platform_readers.id
    }
    workloads = {
      for workload_name, workload_group in azuread_group.workload_admins :
      workload_name => {
        admins  = workload_group.id
        users   = azuread_group.workload_users[workload_name].id
        readers = azuread_group.workload_readers[workload_name].id
      }
    }
  }
}

output "rbac_group_names" {
  description = "RBAC Group names for platform and workloads"
  value = {
    platform = {
      admins  = azuread_group.platform_admins.display_name
      users   = azuread_group.platform_users.display_name
      readers = azuread_group.platform_readers.display_name
    }
    workloads = {
      for workload_name, workload_group in azuread_group.workload_admins :
      workload_name => {
        admins  = workload_group.display_name
        users   = azuread_group.workload_users[workload_name].display_name
        readers = azuread_group.workload_readers[workload_name].display_name
      }
    }
  }
}
