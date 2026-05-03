# =============================================================================
# Resource Groups
# =============================================================================
module "rg_primary" {
  source   = "../../modules/resource_group"
  name     = "rg-${var.workload_name}-${var.environment}-${var.primary_location}"
  location = var.primary_location
  tags     = var.tags
}

module "rg_secondary" {
  source   = "../../modules/resource_group"
  name     = "rg-${var.workload_name}-${var.environment}-${var.secondary_location}"
  location = var.secondary_location
  tags     = var.tags
}

# Data sources to ensure RG exists before modules try to read it
data "azurerm_resource_group" "primary" {
  name = module.rg_primary.name
  depends_on = [module.rg_primary]
}

data "azurerm_resource_group" "secondary" {
  name = module.rg_secondary.name
  depends_on = [module.rg_secondary]
}

# =============================================================================
# Virtual Networks
# =============================================================================
module "vnet_primary" {
  source              = "../../modules/virtual_network"
  name                = "vnet-${var.workload_name}-${var.primary_location}"
  location            = module.rg_primary.location
  resource_group_name = module.rg_primary.name
  address_space       = var.vnet_primary_address_space
  tags                = var.tags

  subnets = {
    "snet-web" = {
      address_prefix = cidrsubnet(var.vnet_primary_address_space[0], 8, 1)
    }
    "snet-pe" = {
      address_prefix = cidrsubnet(var.vnet_primary_address_space[0], 8, 2)
    }
    "snet-appgw" = {
      address_prefix = cidrsubnet(var.vnet_primary_address_space[0], 8, 3)
    }
  }
}

module "vnet_secondary" {
  source              = "../../modules/virtual_network"
  name                = "vnet-${var.workload_name}-${var.secondary_location}"
  location            = module.rg_secondary.location
  resource_group_name = module.rg_secondary.name
  address_space       = var.vnet_secondary_address_space
  tags                = var.tags

  subnets = {
    "snet-web" = {
      address_prefix = cidrsubnet(var.vnet_secondary_address_space[0], 8, 1)
    }
    "snet-pe" = {
      address_prefix = cidrsubnet(var.vnet_secondary_address_space[0], 8, 2)
    }
    "snet-appgw" = {
      address_prefix = cidrsubnet(var.vnet_secondary_address_space[0], 8, 3)
    }
  }
}

# =============================================================================
# Hub Virtual Network
# =============================================================================

module "rg_hub" {
  count    = var.create_hub ? 1 : 0
  source   = "../../modules/resource_group"
  name     = var.hub_resource_group_name
  location = var.primary_location
  tags     = var.tags
}

module "vnet_hub" {
  count               = var.create_hub ? 1 : 0
  source              = "../../modules/virtual_network"
  name                = var.hub_vnet_name
  location            = var.primary_location
  resource_group_name = module.rg_hub[0].name
  address_space       = var.hub_vnet_address_space
  tags                = var.tags

  subnets = {
    "GatewaySubnet" = {
      address_prefix = cidrsubnet(var.hub_vnet_address_space[0], 8, 2)
    }
    "snet-appgw-primary" = {
      address_prefix = cidrsubnet(var.hub_vnet_address_space[0], 8, 3)
    }
    "AzureBastionSubnet" = {
      address_prefix = cidrsubnet(var.hub_vnet_address_space[0], 8, 4)
    }
  }
}

data "azurerm_virtual_network" "hub" {
  count               = var.create_hub ? 0 : 1
  name                = var.hub_vnet_name
  resource_group_name = var.hub_resource_group_name
}

locals {
  hub_vnet_id   = var.create_hub ? module.vnet_hub[0].vnet_id : data.azurerm_virtual_network.hub[0].id
  hub_vnet_name = var.create_hub ? module.vnet_hub[0].vnet_name : data.azurerm_virtual_network.hub[0].name
  hub_rg_name   = var.create_hub ? module.rg_hub[0].name : data.azurerm_virtual_network.hub[0].resource_group_name
}

# =============================================================================
# Hub <-> Spoke VNet Peerings
# =============================================================================

# Primary Spoke to Hub
resource "azurerm_virtual_network_peering" "primary_to_hub" {
  name                      = "peer-prim-to-hub"
  resource_group_name       = module.rg_primary.name
  virtual_network_name      = module.vnet_primary.vnet_name
  remote_virtual_network_id = local.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Hub to Primary Spoke
resource "azurerm_virtual_network_peering" "hub_to_primary" {
  name                      = "peer-hub-to-prim"
  resource_group_name       = local.hub_rg_name
  virtual_network_name      = local.hub_vnet_name
  remote_virtual_network_id = module.vnet_primary.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Secondary Spoke to Hub
resource "azurerm_virtual_network_peering" "secondary_to_hub" {
  name                      = "peer-sec-to-hub"
  resource_group_name       = module.rg_secondary.name
  virtual_network_name      = module.vnet_secondary.vnet_name
  remote_virtual_network_id = local.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Hub to Secondary Spoke
resource "azurerm_virtual_network_peering" "hub_to_secondary" {
  name                      = "peer-hub-to-sec"
  resource_group_name       = local.hub_rg_name
  virtual_network_name      = local.hub_vnet_name
  remote_virtual_network_id = module.vnet_secondary.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
