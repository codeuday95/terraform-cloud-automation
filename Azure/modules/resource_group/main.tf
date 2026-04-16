resource "azurerm_resource_group" "rg" {
  name     = var.name
  location = var.location
  tags     = var.tags
}

resource "azurerm_management_lock" "rg_lock" {
  count              = var.lock_resource_group ? 1 : 0
  name               = "${var.name}-lock"
  scope              = azurerm_resource_group.rg.id
  lock_level         = "CanNotDelete"
  notes              = "Applied by Terraform"
}
