# Network Interface
resource "azurerm_network_interface" "vm" {
  name                = var.nic_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.enable_public_ip ? azurerm_public_ip.vm[0].id : null
  }

  tags = var.tags
}

# Attach NSG to NIC (AzureRM v4.x uses separate association resource)
resource "azurerm_network_interface_security_group_association" "nsg_attachment" {
  count                     = var.attach_nsg ? 1 : 0
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = var.nsg_id

  lifecycle {
    ignore_changes = [network_security_group_id]
  }
}

# Public IP (optional)
resource "azurerm_public_ip" "vm" {
  count               = var.enable_public_ip ? 1 : 0
  name                = "${var.nic_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.public_ip_allocation_method
  sku                 = "Standard"
  domain_name_label   = var.domain_name_label

  tags = var.tags
}
