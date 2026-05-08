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

data "azurerm_client_config" "current" {}

module "key_vault" {
  source              = "../../../modules/key_vault"
  name                = local.kv_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  tags = var.tags
}

resource "azurerm_key_vault_access_policy" "aks_kubelet" {
  key_vault_id = module.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id

  # The Kubelet Identity is what the SecretProviderClass uses to fetch secrets
  object_id = module.aks.kubelet_identity_object_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# Store ACR admin credentials in Key Vault so pipelines and operators
# can retrieve them securely. Requires that the identity running
# Terraform has permissions to set secrets on the Key Vault.
resource "azurerm_key_vault_secret" "acr_admin_username" {
  name         = "acr-admin-username"
  value        = azurerm_container_registry.acr.admin_username
  key_vault_id = module.key_vault.id
}

resource "azurerm_key_vault_secret" "acr_admin_password" {
  name         = "acr-admin-password"
  # The container registry exposes admin_passwords as a list; use the
  # first one. If rotation is used, update this to reference the
  # appropriate password index or rotation mechanism.
  value        = azurerm_container_registry.acr.admin_passwords[0].value
  key_vault_id = module.key_vault.id
}
