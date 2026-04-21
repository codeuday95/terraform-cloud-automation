terraform {
  backend "azurerm" {
    resource_group_name  = "rg-nuatomations-tfstate"
    storage_account_name = "stnuatomationstfstateeas"
    container_name       = "workload-b"
    key                  = "workload-b.tfstate"
  }
}
