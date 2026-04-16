output "policy_definition_ids" {
  description = "Map of policy definition IDs"
  value = {
    allowed_locations   = azurerm_policy_definition.allowed_locations.id
    required_tags       = azurerm_policy_definition.required_tags.id
    allowed_vm_skus     = azurerm_policy_definition.allowed_vm_skus.id
    disk_encryption     = azurerm_policy_definition.require_disk_encryption.id
  }
}

output "initiative_id" {
  description = "Policy Initiative ID"
  value       = azurerm_policy_set_definition.landing_zone_initiative.id
}

output "initiative_name" {
  description = "Policy Initiative name"
  value       = azurerm_policy_set_definition.landing_zone_initiative.name
}
