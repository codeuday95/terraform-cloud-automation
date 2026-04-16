# Read Platform outputs from remote state
data "terraform_remote_state" "platform" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.tfstate_resource_group
    storage_account_name = var.tfstate_storage_account
    container_name       = "platform"
    key                  = "platform.tfstate"
  }
}

# Create workload-specific storage account for tfstate
# This gives the workload team full autonomy over their Terraform state
module "tfstate_storage" {
  source = "../../modules/tfstate_storage"

  storage_account_name     = "st${var.workload_name}${var.environment}${substr(var.location, 0, 3)}tfst"
  resource_group_name      = data.terraform_remote_state.platform.outputs.workload_resource_groups[var.workload_name].name
  location                 = var.location
  container_name           = "${var.workload_name}-tfstate"
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
  allowed_ip_ranges        = var.developer_ips
  enable_public_access     = false
  versioning_enabled       = true
  soft_delete_days         = 7

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Workload    = var.workload_name
      Purpose     = "Terraform State Storage"
    }
  )
}

# Example: Deploy App Service Plan + Web App for workload-b
resource "azurerm_service_plan" "workload_b" {
  name                = "sp-${var.workload_name}-${var.environment}"
  location            = var.location
  resource_group_name = data.terraform_remote_state.platform.outputs.workload_resource_groups[var.workload_name].name
  os_type             = "Linux"
  sku_name            = var.environment == "prod" ? "P1v2" : "B1"

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Workload    = var.workload_name
    }
  )
}

resource "azurerm_linux_web_app" "workload_b" {
  name                = "app-${var.workload_name}-${var.environment}"
  location            = var.location
  resource_group_name = data.terraform_remote_state.platform.outputs.workload_resource_groups[var.workload_name].name
  service_plan_id     = azurerm_service_plan.workload_b.id

  site_config {
    application_stack {
      docker_image_name   = "nginx:latest"
      docker_registry_url = "https://index.docker.io"
    }
  }

  https_only = true

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Workload    = var.workload_name
    }
  )
}

# Example: Container Registry for workload-b
resource "azurerm_container_registry" "workload_b" {
  name                = "cr${replace(var.workload_name, "-", "")}${var.environment}"
  location            = var.location
  resource_group_name = data.terraform_remote_state.platform.outputs.workload_resource_groups[var.workload_name].name
  admin_enabled       = false
  sku                 = var.environment == "prod" ? "Premium" : "Basic"

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Workload    = var.workload_name
    }
  )
}

# Example: Cosmos DB for workload-b
resource "azurerm_cosmosdb_account" "workload_b" {
  name                = "cosmos-${var.workload_name}-${var.environment}"
  location            = var.location
  resource_group_name = data.terraform_remote_state.platform.outputs.workload_resource_groups[var.workload_name].name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  consistency_policy {
    consistency_level = "Session"
  }

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Workload    = var.workload_name
    }
  )
}

# Store Cosmos DB connection string in Key Vault
resource "azurerm_key_vault_secret" "cosmos_connection_string" {
  name         = "cosmos-connection-string"
  value        = azurerm_cosmosdb_account.workload_b.primary_sql_connection_string
  key_vault_id = data.terraform_remote_state.platform.outputs.workload_keyvaults[var.workload_name].id
}

# Store Container Registry credentials in Key Vault
resource "azurerm_key_vault_secret" "acr_login_server" {
  name         = "acr-login-server"
  value        = azurerm_container_registry.workload_b.login_server
  key_vault_id = data.terraform_remote_state.platform.outputs.workload_keyvaults[var.workload_name].id
}

# =============================================================================
# AKS Subnet (dedicated subnet for AKS in hub VNet)
# =============================================================================

resource "azurerm_subnet" "aks" {
  count = var.enable_aks && var.aks_create_aks_subnet ? 1 : 0

  name                 = "subnet-aks-${var.environment}"
  resource_group_name  = data.terraform_remote_state.platform.outputs.workload_resource_groups[var.workload_name].name
  virtual_network_name = "vnet-hub-${var.environment}"
  address_prefixes     = [var.aks_subnet_address_prefix]
}

# =============================================================================
# AKS Cluster Deployment
# =============================================================================

module "aks" {
  count = var.enable_aks ? 1 : 0

  source = "../../modules/aks"

  cluster_name        = var.aks_cluster_name
  location            = var.location
  resource_group_name = data.terraform_remote_state.platform.outputs.workload_resource_groups[var.workload_name].name

  # Cluster Configuration
  kubernetes_version = var.aks_kubernetes_version
  sku_tier           = var.aks_sku_tier

  # Default Node Pool
  default_node_pool_vm_size      = var.aks_default_node_pool_vm_size
  default_pool_autoscale_enabled = var.aks_default_pool_autoscale_enabled
  default_pool_min_count         = var.aks_default_pool_min_count
  default_pool_max_count         = var.aks_default_pool_max_count

  # Network Configuration
  network_plugin = var.aks_network_plugin
  network_policy = "azure"
  vnet_subnet_id = var.aks_vnet_subnet_id != null ? var.aks_vnet_subnet_id : (var.aks_create_aks_subnet ? azurerm_subnet.aks[0].id : data.terraform_remote_state.platform.outputs.workload_subnets[var.workload_name].id)

  # Monitoring (optional)
  enable_container_insights = var.aks_enable_container_insights

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Workload    = var.workload_name
      Purpose     = "AKS Cluster"
    }
  )

  depends_on = [
    data.terraform_remote_state.platform,
    azurerm_subnet.aks
  ]
}
