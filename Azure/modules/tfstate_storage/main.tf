# Storage Account for Terraform State (secure by default)
resource "azurerm_storage_account" "tfstate" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type

  # Security: minimum TLS 1.2
  min_tls_version = "TLS1_2"

  # Deny public access by default (firewall rules can allow specific IPs/subnets)
  public_network_access_enabled = var.enable_public_access

  tags = merge(
    var.tags,
    {
      Purpose = "Terraform State Storage"
    }
  )
}

# Network rules: Restrict access by default
resource "azurerm_storage_account_network_rules" "tfstate" {
  storage_account_id = azurerm_storage_account.tfstate.id
  default_action     = var.enable_public_access ? "Allow" : "Deny"
  bypass             = ["AzureServices"] # Allow Azure services (GitHub Actions)
  ip_rules           = var.allowed_ip_ranges
  virtual_network_subnet_ids = var.allowed_subnet_ids
}

# Storage Container for Terraform state
resource "azurerm_storage_container" "tfstate" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private" # Never public
}
