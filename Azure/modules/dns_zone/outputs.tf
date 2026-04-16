output "dns_zone_name" {
  description = "DNS Zone name"
  value       = azurerm_dns_zone.main.name
}

output "dns_zone_id" {
  description = "DNS Zone ID"
  value       = azurerm_dns_zone.main.id
}

output "dns_record_fqdn" {
  description = "Fully qualified domain name of the A record"
  value       = azurerm_dns_a_record.vm_record.fqdn
}

output "name_servers" {
  description = "List of DNS name servers for the zone"
  value       = azurerm_dns_zone.main.name_servers
}
