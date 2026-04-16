# Azure Bastion for secure RDP/SSH access

# Public IP for Bastion
resource "azurerm_public_ip" "bastion" {
  name                = "${var.bastion_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

# Bastion Host
resource "azurerm_bastion_host" "main" {
  name                = var.bastion_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  # Bastion SKU
  sku                   = var.bastion_sku
  copy_paste_enabled    = var.copy_paste_enabled
  file_copy_enabled     = var.file_copy_enabled
  shareable_link_enabled = var.shareable_link_enabled

  # Scale units (affects concurrent connections)
  scale_units           = var.scale_units

  tags = var.tags
}

# Optional: NSG for Bastion Subnet
resource "azurerm_network_security_group" "bastion" {
  count               = var.create_bastion_nsg ? 1 : 0
  name                = "${var.bastion_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow HTTPS from Internet (for Bastion web access)
  security_rule {
    name                       = "AllowHttpsInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Allow SSH/RDP from Bastion subnet (internal)
  security_rule {
    name                       = "AllowSshRdpFromBastion"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "AzureBastionSubnet"
    destination_address_prefix = "*"
  }

  tags = var.tags
}
