# Random password for VM admin
resource "random_password" "admin" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Network Security Group
module "nsg" {
  source = "../network_security_group"

  nsg_name        = var.nsg_name
  location        = var.location
  resource_group_name = var.resource_group_name
  rdp_allowed_ips = var.rdp_allowed_ips
  tags            = var.tags
}

# Network Interface
module "nic" {
  source = "../network_interface"

  nic_name            = var.nic_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  enable_public_ip                      = var.enable_public_ip
  public_ip_allocation_method           = var.public_ip_allocation_method
  domain_name_label                     = var.vm_name
  nsg_id                                = module.nsg.id
  attach_nsg                            = true
  tags                = var.tags
}

# Windows VM with Trusted Launch Security (AzureRM v4.x)
resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = random_password.admin.result
  network_interface_ids = [module.nic.id]

  # Availability Zone
  # zone = var.availability_zone

  # Trusted Launch - Secure Boot and vTPM (standalone attributes in v4.x)
  secure_boot_enabled = true
  vtpm_enabled        = true

  # Boot Diagnostics
  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_storage_account_name != null ? "https://${var.boot_diagnostics_storage_account_name}.blob.core.windows.net/" : null
  }

  os_disk {
    name                = "${var.vm_name}-osdisk"
    storage_account_type = var.os_disk_storage_type
    caching             = "ReadWrite"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  computer_name = var.computer_name

  tags = var.tags
}

# Custom Script Extension for software installation using Chocolatey
resource "azurerm_virtual_machine_extension" "custom_script" {
  name                 = "${var.vm_name}-customscript"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
{
  "fileUris": ["https://chocolatey.org/install.ps1"],
  "commandToExecute": "powershell -ExecutionPolicy Bypass -Command \"& { . ./install.ps1; choco feature enable -n allowGlobalConfirmation; choco install googlechrome -y; choco install notepadplusplus -y; choco install treesizefree -y; choco install 7zip -y; choco install firefox -y }\""
}
SETTINGS

  depends_on = [azurerm_windows_virtual_machine.vm]
}

# Store admin credentials in Key Vault
resource "azurerm_key_vault_secret" "admin_username" {
  name         = "${var.vm_name}-admin-username"
  value        = var.admin_username
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_windows_virtual_machine.vm]
}

resource "azurerm_key_vault_secret" "admin_password" {
  name         = "${var.vm_name}-admin-password"
  value        = random_password.admin.result
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_windows_virtual_machine.vm]
}
