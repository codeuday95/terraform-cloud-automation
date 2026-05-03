data "azurerm_client_config" "current" {}

module "key_vault" {
  source              = "../../modules/key_vault"
  name                = "kv${var.workload_name}${random_string.global.result}"
  location            = module.rg_primary.location
  resource_group_name = module.rg_primary.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = var.tags
}

resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = module.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Purge", "Recover"
  ]
}

# VM credentials (SSH)
resource "tls_private_key" "vm_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault_secret" "vm_username" {
  name         = "vm-admin-username"
  value        = "azureadmin"
  key_vault_id = module.key_vault.id
  depends_on   = [azurerm_key_vault_access_policy.current_user]
}

resource "azurerm_key_vault_secret" "vm_ssh_private" {
  name         = "vm-ssh-private-key"
  value        = tls_private_key.vm_ssh.private_key_pem
  key_vault_id = module.key_vault.id
  depends_on   = [azurerm_key_vault_access_policy.current_user]
}

# SQL passwords
resource "random_password" "sql_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_key_vault_secret" "sql_username" {
  name         = "sql-admin-username"
  value        = "sqladmin"
  key_vault_id = module.key_vault.id
  depends_on   = [azurerm_key_vault_access_policy.current_user]
}

resource "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-admin-password"
  value        = random_password.sql_password.result
  key_vault_id = module.key_vault.id
  depends_on   = [azurerm_key_vault_access_policy.current_user]
}

# Centralized Hub Bastion
module "bastion_hub" {
  count               = var.create_hub ? 1 : 0
  source              = "../../modules/bastion"
  bastion_name        = "bas-${var.workload_name}-hub"
  location            = var.primary_location
  resource_group_name = module.rg_hub[0].name
  bastion_subnet_id   = module.vnet_hub[0].subnets["AzureBastionSubnet"].id
  bastion_sku         = "Standard"
  tags                = var.tags
}
