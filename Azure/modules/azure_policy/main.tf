# Azure Policy Initiative for Landing Zone

# Policy: Allowed Locations
resource "azurerm_policy_definition" "allowed_locations" {
  name                = "allowed-locations-${var.policy_scope}"
  display_name        = "Allowed Locations for ${var.policy_scope}"
  policy_type         = "Custom"
  mode                = "All"
  description         = "Restricts resource creation to allowed locations"

  policy_rule = jsonencode({
    if = {
      field = "location"
      notIn = var.allowed_locations
    }
    then = {
      effect = "Deny"
    }
  })

  parameters = jsonencode({
    allowedLocations = {
      type  = "Array"
      metadata = {
        displayName = "Allowed locations"
        strongType = "location"
      }
    }
  })
}

# Policy: Required Tags on Resources
resource "azurerm_policy_definition" "required_tags" {
  name                = "required-tags-${var.policy_scope}"
  display_name        = "Required Tags for ${var.policy_scope}"
  policy_type         = "Custom"
  mode                = "Indexed"
  description         = "Requires specific tags on all resources"

  policy_rule = jsonencode({
    if = {
      anyOf = [
        for tag in var.required_tags : {
          field = "tags[${tag}]"
          exists = false
        }
      ]
    }
    then = {
      effect = "Deny"
    }
  })

  parameters = jsonencode({
    requiredTags = {
      type = "Array"
      metadata = {
        displayName = "Required Tags"
      }
    }
  })
}

# Policy: Allowed VM SKUs
resource "azurerm_policy_definition" "allowed_vm_skus" {
  name                = "allowed-vm-skus-${var.policy_scope}"
  display_name        = "Allowed VM SKUs for ${var.policy_scope}"
  policy_type         = "Custom"
  mode                = "Indexed"
  description         = "Restricts VM sizes to approved SKUs"

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field = "type"
          equals = "Microsoft.Compute/virtualMachines"
        },
        {
          field = "Microsoft.Compute/virtualMachines/sku"
          notIn = var.allowed_vm_skus
        }
      ]
    }
    then = {
      effect = "Deny"
    }
  })
}

# Policy: Require Disk Encryption
resource "azurerm_policy_definition" "require_disk_encryption" {
  name                = "require-disk-encryption-${var.policy_scope}"
  display_name        = "Require Disk Encryption for ${var.policy_scope}"
  policy_type         = "Custom"
  mode                = "Indexed"
  description         = "Requires encryption at rest for all disks"

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field = "type"
          equals = "Microsoft.Compute/disks"
        },
        {
          field = "Microsoft.Compute/disks/encryptionSettingsCollection.enabled"
          notEquals = true
        }
      ]
    }
    then = {
      effect = "Deny"
    }
  })
}

# Policy Initiative (Group of policies)
resource "azurerm_policy_set_definition" "landing_zone_initiative" {
  name                = "landing-zone-initiative-${var.policy_scope}"
  display_name        = "Landing Zone Policy Initiative for ${var.policy_scope}"
  policy_type         = "Custom"
  description         = "Comprehensive policy initiative for landing zone governance"

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.allowed_locations.id
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.required_tags.id
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.allowed_vm_skus.id
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require_disk_encryption.id
  }
}
