# Data source for bootstrap storage account (created in bootstrap layer)
data "azurerm_storage_account" "bootstrap" {
  name                = var.tfstate_storage_account
  resource_group_name = var.tfstate_resource_group
}

# =============================================================================
# Platform Shared Services
# =============================================================================

# Rely on the Platform Resource Group already created by the bootstrap script
data "azurerm_resource_group" "platform" {
  name = var.tfstate_resource_group
}

# Hub Virtual Network
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${var.environment}"
  location            = data.azurerm_resource_group.platform.location
  resource_group_name = data.azurerm_resource_group.platform.name
  address_space       = [var.hub_vnet_cidr]

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      VNetType    = "Hub"
    }
  )
}

# Hub Subnets
resource "azurerm_subnet" "hub_subnets" {
  for_each = var.hub_vnet_subnets

  name                 = each.key
  resource_group_name  = data.azurerm_resource_group.platform.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [each.value.cidr]

  depends_on = [azurerm_virtual_network.hub]
}

# Spoke Virtual Network for Workloads
resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-spoke-${var.environment}"
  location            = data.azurerm_resource_group.platform.location
  resource_group_name = data.azurerm_resource_group.platform.name
  address_space       = [var.spoke_vnet_cidr]

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      VNetType    = "Spoke"
    }
  )
}

# VNet Peering: Hub to Spoke
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-spoke"
  resource_group_name       = data.azurerm_resource_group.platform.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# VNet Peering: Spoke to Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-spoke-to-hub"
  resource_group_name       = data.azurerm_resource_group.platform.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Workload Subnets (within the Spoke VNet)
resource "azurerm_subnet" "workload_subnets" {
  for_each = var.workload_subnets

  name                 = "subnet-${each.key}-${var.environment}"
  resource_group_name  = data.azurerm_resource_group.platform.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [each.value.cidr]

  depends_on = [azurerm_virtual_network.spoke]
}

# Log Analytics Workspace (shared)
resource "azurerm_log_analytics_workspace" "platform" {
  name                = "law-platform-${var.environment}"
  location            = data.azurerm_resource_group.platform.location
  resource_group_name = data.azurerm_resource_group.platform.name
  sku                 = "PerGB2018"
  retention_in_days   = var.environment == "prod" ? 90 : 30

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Purpose     = "Platform Logging"
    }
  )
}

# Shared Key Vault for platform secrets
resource "azurerm_key_vault" "platform" {
  name                = "kv-platform-${var.environment == "prod" ? "p" : var.environment == "staging" ? "s" : "d"}-${substr(random_id.platform_kv.hex, 0, 4)}"
  location            = data.azurerm_resource_group.platform.location
  resource_group_name = data.azurerm_resource_group.platform.name
  tenant_id           = data.azuread_client_config.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled  = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = var.environment == "prod" ? true : false

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Purpose     = "Platform Secrets"
    }
  )
}

# RBAC: Key Vault Administrator for current user on platform KV
resource "azurerm_role_assignment" "kv_admin_platform" {
  scope                = azurerm_key_vault.platform.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azuread_client_config.current.object_id
}

# =============================================================================
# Landing Zones for Each Workload
# =============================================================================

# Create landing zone module for each workload
module "landing_zone" {
  source = "../modules/landing_zone"

  for_each = { for workload in var.workloads : workload.name => workload }

  workload_name          = each.value.name
  environment            = var.environment
  location               = var.location
  vnet_cidr              = lookup(each.value, "cidr", "")
  use_hub_subnet         = true
  hub_vnet_name          = azurerm_virtual_network.spoke.name
  hub_resource_group     = data.azurerm_resource_group.platform.name
  hub_subnet_name        = "subnet-${each.key}-${var.environment}"
  tenant_id              = data.azuread_client_config.current.tenant_id
  enable_key_vault       = true
  enable_storage_account = true
  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )

  depends_on = [azurerm_subnet.workload_subnets]
}

# =============================================================================
# Service Principals and Identity
# =============================================================================

# Service Principal for Platform (used by platform Terraform)
resource "azuread_application" "platform" {
  display_name = "sp-platform-${var.environment}"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "platform" {
  client_id = azuread_application.platform.client_id
  owners    = [data.azuread_client_config.current.object_id]
}

# Platform SP: Contributor on platform RG
resource "azurerm_role_assignment" "platform_rg_contributor" {
  scope                = data.azurerm_resource_group.platform.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.platform.object_id
}

# Service Principals for each workload (used by workload Terraform)
resource "azuread_application" "workload" {
  for_each = { for workload in var.workloads : workload.name => workload }

  display_name = "sp-${each.key}-${var.environment}"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "workload" {
  for_each = { for workload in var.workloads : workload.name => workload }

  client_id = azuread_application.workload[each.key].client_id
  owners    = [data.azuread_client_config.current.object_id]
}

# Workload SP: Contributor on their respective workload RG
resource "azurerm_role_assignment" "workload_rg_contributor" {
  for_each = { for workload in var.workloads : workload.name => workload }

  scope                = module.landing_zone[each.key].resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.workload[each.key].object_id
}

# Workload SP: Reader on Platform State Storage Account (to read terraform_remote_state)
resource "azurerm_role_assignment" "workload_platform_state_reader" {
  for_each             = { for workload in var.workloads : workload.name => workload }
  scope                = data.azurerm_storage_account.bootstrap.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.workload[each.key].object_id
}

# Workload SP: Storage Blob Data Reader on Platform State Storage Account
resource "azurerm_role_assignment" "workload_platform_blob_reader" {
  for_each             = { for workload in var.workloads : workload.name => workload }
  scope                = data.azurerm_storage_account.bootstrap.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_service_principal.workload[each.key].object_id
}

# Workload SP: Network Contributor on their specific subnet
resource "azurerm_role_assignment" "workload_subnet_contributor" {
  for_each             = { for workload in var.workloads : workload.name => workload }
  scope                = azurerm_subnet.workload_subnets[each.key].id
  role_definition_name = "Network Contributor"
  principal_id         = azuread_service_principal.workload[each.key].object_id
}

# Workload SP: Reader on their specific subnet
resource "azurerm_role_assignment" "workload_subnet_reader" {
  for_each             = { for workload in var.workloads : workload.name => workload }
  scope                = azurerm_subnet.workload_subnets[each.key].id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.workload[each.key].object_id
}

# Workload SP: Reader on their respective workload RG
resource "azurerm_role_assignment" "workload_rg_reader" {
  for_each             = { for workload in var.workloads : workload.name => workload }
  scope                = module.landing_zone[each.key].resource_group_id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.workload[each.key].object_id
}

# Generate client secrets for Platform SP
resource "azuread_application_password" "platform" {
  application_id = azuread_application.platform.id
  display_name          = "platform-terraform-secret"
  end_date_relative     = "8760h" # 1 year
}

# Generate client secrets for each Workload SP
resource "azuread_application_password" "workload" {
  for_each = { for workload in var.workloads : workload.name => workload }

  application_id = azuread_application.workload[each.key].id
  display_name          = "${each.key}-terraform-secret"
  end_date_relative     = "8760h" # 1 year
}

# =============================================================================
# Key Vault Secrets Storage
# =============================================================================

# Store Platform SP credentials in platform Key Vault
resource "azurerm_key_vault_secret" "platform_client_id" {
  name         = "${azuread_application.platform.display_name}-client-id"
  value        = azuread_application.platform.client_id
  key_vault_id = azurerm_key_vault.platform.id

  depends_on = [azurerm_role_assignment.kv_admin_platform]
}

resource "azurerm_key_vault_secret" "platform_object_id" {
  name         = "${azuread_application.platform.display_name}-object-id"
  value        = azuread_service_principal.platform.object_id
  key_vault_id = azurerm_key_vault.platform.id

  depends_on = [azurerm_role_assignment.kv_admin_platform]
}

resource "azurerm_key_vault_secret" "platform_client_secret" {
  name         = "${azuread_application.platform.display_name}-client-secret"
  value        = azuread_application_password.platform.value
  key_vault_id = azurerm_key_vault.platform.id

  depends_on = [azurerm_role_assignment.kv_admin_platform]
}

resource "azurerm_key_vault_secret" "platform_sp_name" {
  name         = "${azuread_application.platform.display_name}-name"
  value        = azuread_application.platform.display_name
  key_vault_id = azurerm_key_vault.platform.id

  depends_on = [azurerm_role_assignment.kv_admin_platform]
}

# Store Workload SP credentials in their respective workload Key Vaults
resource "azurerm_key_vault_secret" "workload_client_id" {
  for_each = { for workload in var.workloads : workload.name => workload }

  name         = "${azuread_application.workload[each.key].display_name}-client-id"
  value        = azuread_application.workload[each.key].client_id
  key_vault_id = module.landing_zone[each.key].key_vault_id

  depends_on = [azurerm_role_assignment.kv_admin_workload]
}

resource "azurerm_key_vault_secret" "workload_object_id" {
  for_each = { for workload in var.workloads : workload.name => workload }

  name         = "${azuread_application.workload[each.key].display_name}-object-id"
  value        = azuread_service_principal.workload[each.key].object_id
  key_vault_id = module.landing_zone[each.key].key_vault_id

  depends_on = [azurerm_role_assignment.kv_admin_workload]
}

resource "azurerm_key_vault_secret" "workload_client_secret" {
  for_each = { for workload in var.workloads : workload.name => workload }

  name         = "${azuread_application.workload[each.key].display_name}-client-secret"
  value        = azuread_application_password.workload[each.key].value
  key_vault_id = module.landing_zone[each.key].key_vault_id

  depends_on = [azurerm_role_assignment.kv_admin_workload]
}

resource "azurerm_key_vault_secret" "workload_sp_name" {
  for_each = { for workload in var.workloads : workload.name => workload }

  name         = "${azuread_application.workload[each.key].display_name}-name"
  value        = azuread_application.workload[each.key].display_name
  key_vault_id = module.landing_zone[each.key].key_vault_id

  depends_on = [azurerm_role_assignment.kv_admin_workload]
}

# RBAC: Key Vault Administrator for current user on each workload KV
resource "azurerm_role_assignment" "kv_admin_workload" {
  for_each = { for workload in var.workloads : workload.name => workload }

  scope                = module.landing_zone[each.key].key_vault_id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azuread_client_config.current.object_id

  depends_on = [module.landing_zone]
}

# RBAC: Key Vault Secrets Officer for workload SP on its own KV
resource "azurerm_role_assignment" "kv_secrets_officer_workload" {
  for_each = { for workload in var.workloads : workload.name => workload }

  scope                = module.landing_zone[each.key].key_vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azuread_service_principal.workload[each.key].object_id

  depends_on = [module.landing_zone]
}

# RBAC: Key Vault Secrets User for workload SPs on platform KV (read-only access to secrets)
resource "azurerm_role_assignment" "kv_secrets_user_platform" {
  for_each = { for workload in var.workloads : workload.name => workload }

  scope                = azurerm_key_vault.platform.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.workload[each.key].object_id
}

# =============================================================================
# Azure Policy
# =============================================================================

# Azure Policy: Allowed Locations
resource "azurerm_policy_definition" "allowed_locations" {
  name         = "AllowedLocations-${var.environment}"
  display_name = "Allowed Locations - ${var.environment}"
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    if = {
      field = "location"
      notIn = var.allowed_regions
    }
    then = {
      effect = "Deny"
    }
  })
}

# =============================================================================
# Random IDs
# =============================================================================

resource "random_id" "platform_kv" {
  byte_length = 4
}

# =============================================================================
# RBAC Groups
# =============================================================================

# Platform RBAC Groups
resource "azuread_group" "platform_admins" {
  display_name     = var.rbac_groups.platform.admins
  security_enabled = true
  description      = "Platform administrators with Owner access to platform resources"
}

resource "azuread_group" "platform_users" {
  display_name     = var.rbac_groups.platform.users
  security_enabled = true
  description      = "Platform users with Contributor access to platform resources"
}

resource "azuread_group" "platform_readers" {
  display_name     = var.rbac_groups.platform.readers
  security_enabled = true
  description      = "Platform readers with Reader access to platform resources"
}

# Platform Role Assignments
resource "azurerm_role_assignment" "platform_admins" {
  scope                = data.azurerm_resource_group.platform.id
  role_definition_name = "Owner"
  principal_id         = azuread_group.platform_admins.object_id
}

resource "azurerm_role_assignment" "platform_users" {
  scope                = data.azurerm_resource_group.platform.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.platform_users.object_id
}

resource "azurerm_role_assignment" "platform_readers" {
  scope                = data.azurerm_resource_group.platform.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.platform_readers.object_id
}

# Workload RBAC Groups
resource "azuread_group" "workload_admins" {
  for_each = var.rbac_groups.workloads

  display_name     = each.value.admins
  security_enabled = true
  description      = "Admins for ${each.key} with Owner access"
}

resource "azuread_group" "workload_users" {
  for_each = var.rbac_groups.workloads

  display_name     = each.value.users
  security_enabled = true
  description      = "Users for ${each.key} with Contributor access"
}

resource "azuread_group" "workload_readers" {
  for_each = var.rbac_groups.workloads

  display_name     = each.value.readers
  security_enabled = true
  description      = "Readers for ${each.key} with Reader access"
}

# Workload Role Assignments
resource "azurerm_role_assignment" "workload_admins" {
  for_each = var.rbac_groups.workloads

  scope                = module.landing_zone[each.key].resource_group_id
  role_definition_name = "Owner"
  principal_id         = azuread_group.workload_admins[each.key].object_id
}

resource "azurerm_role_assignment" "workload_users" {
  for_each = var.rbac_groups.workloads

  scope                = module.landing_zone[each.key].resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.workload_users[each.key].object_id
}

resource "azurerm_role_assignment" "workload_readers" {
  for_each = var.rbac_groups.workloads

  scope                = module.landing_zone[each.key].resource_group_id
  role_definition_name = "Reader"
  principal_id         = azuread_group.workload_readers[each.key].object_id
}

# Add workload SPs to their respective admin groups
resource "azuread_group_member" "workload_sp_admins" {
  for_each = { for workload in var.workloads : workload.name => workload }

  group_object_id  = azuread_group.workload_admins[each.key].object_id
  member_object_id = azuread_service_principal.workload[each.key].object_id
}

# =============================================================================
# Data Sources
# =============================================================================

data "azuread_client_config" "current" {}
data "azurerm_client_config" "current" {}
