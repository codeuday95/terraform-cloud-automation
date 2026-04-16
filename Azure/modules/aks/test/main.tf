# Test configuration for AKS module
# This creates all required resources for testing the AKS module

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      purge_soft_deleted_keys_on_destroy = true
    }
  }
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
}

# Resource group for testing
resource "azurerm_resource_group" "test" {
  name     = "rg-aks-test-${var.environment}"
  location = var.location
  tags = {
    Purpose = "AKS Module Test"
  }
}

# VNet for AKS
resource "azurerm_virtual_network" "test" {
  name                = "vnet-aks-test"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  address_space       = ["10.100.0.0/16"]
  tags = {
    Purpose = "AKS Module Test"
  }
}

# Subnet for AKS (500+ IPs)
resource "azurerm_subnet" "aks" {
  name                 = "subnet-aks"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.100.0.0/20"]  # 4094 IPs
}

# AKS Cluster Module
module "aks" {
  source = "../"

  cluster_name        = "aks-test-${var.environment}"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name

  # Cluster Configuration
  kubernetes_version = null  # Latest stable
  sku_tier           = "Free"

  # Default Node Pool
  default_node_pool_vm_size          = "Standard_B2s_v2"
  default_pool_autoscale_enabled     = true
  default_pool_min_count             = 1
  default_pool_max_count             = 3

  # Network Configuration
  network_plugin  = "azure"
  network_policy  = "azure"
  vnet_subnet_id  = azurerm_subnet.aks.id

  # Monitoring (optional - disabled for this test)
  enable_container_insights = false

  tags = {
    Environment = var.environment
    Purpose     = "AKS Module Test"
  }

  depends_on = [azurerm_subnet.aks]
}
