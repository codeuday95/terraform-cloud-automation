resource "azurerm_storage_account" "sa" {
  name                     = var.name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  https_traffic_only_enabled = var.https_traffic_only_enabled
  min_tls_version          = var.min_tls_version

  tags = var.tags
}
