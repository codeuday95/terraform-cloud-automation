# Linux Virtual Machine Module

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Random password for Linux VM admin
resource "random_password" "admin" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_network_interface" "linux_vm" {
  name                = "${var.vm_name}-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.enable_public_ip ? azurerm_public_ip.linux_vm[0].id : null
  }

  tags = var.tags
}

resource "azurerm_public_ip" "linux_vm" {
  count = var.enable_public_ip ? 1 : 0

  name                = "${var.vm_name}-pip"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.vm_name

  tags = var.tags
}

# Network Security Group
module "nsg" {
  source = "../network_security_group"

  nsg_name            = var.nsg_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = var.resource_group_name
  rdp_allowed_ips     = var.ssh_allowed_ips
  inbound_port        = "22"
  inbound_rule_name   = "AllowSSH"
  tags                = var.tags
}

# Attach NSG to NIC only if provided (skip if empty)
resource "azurerm_network_interface_security_group_association" "nsg_attachment" {
  count                     = var.attach_nsg ? 1 : 0
  network_interface_id      = azurerm_network_interface.linux_vm.id
  network_security_group_id = module.nsg.id

  lifecycle {
    ignore_changes = [network_security_group_id]
  }
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                            = var.vm_name
  location                        = data.azurerm_resource_group.rg.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = random_password.admin.result
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.linux_vm.id,
  ]

  dynamic "admin_ssh_key" {
    for_each = var.admin_ssh_public_key != "" && var.admin_ssh_public_key != null ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.admin_ssh_public_key
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_storage_account_type
  }

  source_image_reference {
    publisher = var.source_image_publisher
    offer     = var.source_image_offer
    sku       = var.source_image_sku
    version   = var.source_image_version
  }

  dynamic "boot_diagnostics" {
    for_each = var.enable_boot_diagnostics ? [1] : []

    content {
      storage_account_uri = var.boot_diagnostics_storage_account_uri
    }
  }

  tags = var.tags

  depends_on = [
    azurerm_network_interface_security_group_association.nsg_attachment
  ]
}

# Store admin credentials in Key Vault
resource "azurerm_key_vault_secret" "admin_username" {
  name         = "${var.vm_name}-admin-username"
  value        = var.admin_username
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_linux_virtual_machine.linux_vm]
}

resource "azurerm_key_vault_secret" "admin_password" {
  name         = "${var.vm_name}-admin-password"
  value        = random_password.admin.result
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_linux_virtual_machine.linux_vm]
}
