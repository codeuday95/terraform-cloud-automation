provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-wkld-d-dev-eastus"
    storage_account_name = "tfstatewkldd95"
    container_name       = "tfstate"
    key                  = "wkld-d-infra.tfstate"
  }
}

