# Resource Group for the workload
resource "azurerm_resource_group" "workload" {
  name     = "rg-${var.workload_name}-${var.environment}"
  location = var.location

  tags = merge(
    var.tags,
    {
      Workload  = var.workload_name
      Purpose   = "Workload Resources"
    }
  )
}

# Virtual Network (only if not using hub subnet)
resource "azurerm_virtual_network" "workload" {
  count = var.use_hub_subnet ? 0 : 1

  name                = "vnet-${var.workload_name}-${var.environment}"
  location            = azurerm_resource_group.workload.location
  resource_group_name = azurerm_resource_group.workload.name
  address_space       = [var.vnet_cidr]

  tags = merge(
    var.tags,
    {
      Workload   = var.workload_name
      VNetType   = "Workload"
    }
  )
}

# Subnet within workload VNet (only if not using hub subnet)
resource "azurerm_subnet" "workload" {
  count = var.use_hub_subnet ? 0 : 1

  name                 = "subnet-${var.workload_name}-${var.environment}"
  resource_group_name  = azurerm_resource_group.workload.name
  virtual_network_name = azurerm_virtual_network.workload[0].name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 2, 0)]
}

# Hub Subnet reference (only if using hub subnet)
data "azurerm_subnet" "hub" {
  count = var.use_hub_subnet ? 1 : 0

  name                 = var.hub_subnet_name
  virtual_network_name = var.hub_vnet_name
  resource_group_name  = var.hub_resource_group
}

# Key Vault for the workload
resource "azurerm_key_vault" "workload" {
  count = var.enable_key_vault ? 1 : 0

  name                = "kv-${var.workload_name}-${var.environment == "prod" ? "p" : var.environment == "staging" ? "s" : "d"}-${substr(random_id.kv.hex, 0, 4)}"
  location            = azurerm_resource_group.workload.location
  resource_group_name = azurerm_resource_group.workload.name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled  = var.environment == "prod" ? true : false

  tags = merge(
    var.tags,
    {
      Workload = var.workload_name
      Purpose  = "Workload Secrets"
    }
  )
}

# Storage Account for the workload
resource "azurerm_storage_account" "workload" {
  count = var.enable_storage_account ? 1 : 0

  name = "st${replace(var.workload_name, "-", "")}${var.environment == "prod" ? "p" : var.environment == "staging" ? "s" : "d"}${substr(random_id.storage.hex, 0, 4)}"
  location = azurerm_resource_group.workload.location
  resource_group_name = azurerm_resource_group.workload.name

  account_tier                   = "Standard"
  account_replication_type       = "LRS"
  https_traffic_only_enabled      = true
  min_tls_version                = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = merge(
    var.tags,
    {
      Workload = var.workload_name
      Purpose  = "Workload Storage"
    }
  )
}

# Random IDs for resource names
resource "random_id" "kv" {
  byte_length = 4
}

resource "random_id" "storage" {
  byte_length = 4
}

# Storage Container for the workload's Terraform state
resource "azurerm_storage_container" "tfstate" {
  count = var.enable_storage_account ? 1 : 0

  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.workload[0].id
  container_access_type = "private"
}
