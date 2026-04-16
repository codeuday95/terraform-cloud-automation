# DNS Zone
resource "azurerm_dns_zone" "main" {
  name                = var.dns_zone_name
  resource_group_name = var.resource_group_name
}

# A record for the VM
resource "azurerm_dns_a_record" "vm_record" {
  name                = var.record_name
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = var.resource_group_name
  ttl                 = var.ttl
  records             = [var.vm_public_ip]
}
