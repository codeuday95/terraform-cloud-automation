output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = azurerm_virtual_network.vnet.name
}

output "subnets" {
  description = "Subnets map"
  value = {
    for subnet in azurerm_subnet.subnet :
    subnet.name => {
      id               = subnet.id
      address_prefixes = subnet.address_prefixes
    }
  }
}
