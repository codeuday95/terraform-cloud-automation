resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
  tags     = var.tags
}

module "vnet" {
  source              = "../../../modules/virtual_network"
  name                = local.vnet_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = var.vnet_address_space

  subnets = {
    "snet-aks" = {
      address_prefix = var.aks_subnet_address_prefix
    }
  }

  tags = var.tags
}

resource "azurerm_container_registry" "acr" {
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = true

  tags = var.tags
}

module "aks" {
  source              = "../../../modules/aks"
  cluster_name        = local.aks_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  # Networking
  vnet_subnet_id = module.vnet.subnets["snet-aks"].id
  network_plugin = "azure"

  # Default Node Pool
  default_node_pool_name          = "default"
  default_node_pool_vm_size       = "Standard_D2s_v3"
  default_pool_min_count          = 1
  default_pool_max_count          = 3
  default_pool_availability_zones = []

  # Identity & ACR Binding
  use_managed_identity    = true
  create_role_assignments = false

  # Construct the ACR ID manually so it's a known string at plan-time
  # Commented out because current user only has Contributor access (cannot write Role Assignments)
  # acr_ids = [
  #   nonsensitive("/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.ContainerRegistry/registries/${azurerm_container_registry.acr.name}")
  # ]

  depends_on = [azurerm_resource_group.rg]

  tags = var.tags
}
