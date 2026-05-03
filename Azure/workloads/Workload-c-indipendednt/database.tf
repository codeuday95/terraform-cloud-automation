resource "random_string" "sql" {
  length  = 6
  special = false
  upper   = false
}

# =============================================================================
# Primary SQL Server
# =============================================================================
module "sql_primary" {
  source               = "../../modules/azure_sql"
  server_name          = "sql-${var.workload_name}-pri-${random_string.sql.result}"
  resource_group_name  = module.rg_primary.name
  location             = module.rg_primary.location
  admin_username       = azurerm_key_vault_secret.sql_username.value
  admin_password       = azurerm_key_vault_secret.sql_password.value
  create_database      = true
  database_name        = "db-${var.workload_name}"
  sku_name             = "Basic"
  tags                 = var.tags
}

# =============================================================================
# Secondary SQL Server
# =============================================================================
module "sql_secondary" {
  source               = "../../modules/azure_sql"
  server_name          = "sql-${var.workload_name}-sec-${random_string.sql.result}"
  resource_group_name  = module.rg_secondary.name
  location             = module.rg_secondary.location
  admin_username       = azurerm_key_vault_secret.sql_username.value
  admin_password       = azurerm_key_vault_secret.sql_password.value
  create_database      = false
  tags                 = var.tags
}

# =============================================================================
# Auto-Failover Group
# =============================================================================
resource "azurerm_mssql_failover_group" "fog" {
  name      = "fog-${var.workload_name}-${random_string.sql.result}"
  server_id = module.sql_primary.server_id
  databases = [module.sql_primary.database_id]

  partner_server {
    id = module.sql_secondary.server_id
  }

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }
}

# =============================================================================
# Private DNS Zone & Endpoints
# =============================================================================
resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = module.rg_primary.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "primary" {
  name                  = "link-primary-vnet"
  resource_group_name   = module.rg_primary.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = module.vnet_primary.vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "secondary" {
  name                  = "link-secondary-vnet"
  resource_group_name   = module.rg_primary.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = module.vnet_secondary.vnet_id
}

resource "azurerm_private_endpoint" "sql_primary" {
  name                = "pe-sql-primary"
  location            = module.rg_primary.location
  resource_group_name = module.rg_primary.name
  subnet_id           = module.vnet_primary.subnets["snet-pe"].id

  private_service_connection {
    name                           = "psc-sql-pri"
    private_connection_resource_id = module.sql_primary.server_id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "pdzg-sql"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}

resource "azurerm_private_endpoint" "sql_secondary" {
  name                = "pe-sql-secondary"
  location            = module.rg_secondary.location
  resource_group_name = module.rg_secondary.name
  subnet_id           = module.vnet_secondary.subnets["snet-pe"].id

  private_service_connection {
    name                           = "psc-sql-sec"
    private_connection_resource_id = module.sql_secondary.server_id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "pdzg-sql"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}
