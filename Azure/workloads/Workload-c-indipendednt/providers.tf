provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy       = true
      purge_soft_deleted_keys_on_destroy = true
    }
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
  }

  # Utilizing `az login` User CLI context automatically instead of OIDC Service Principal overrides
  subscription_id = var.subscription_id
}

provider "azuread" {
  # Automatic tenant resolution via standard az CLI authentication context
}
