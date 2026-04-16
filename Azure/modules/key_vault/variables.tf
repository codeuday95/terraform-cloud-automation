variable "name" {
  description = "Name of the Key Vault"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "sku_name" {
  description = "SKU name (standard or premium)"
  type        = string
  default     = "standard"
}

variable "enabled_for_deployment" {
  description = "Whether the Key Vault can be used for deployment"
  type        = bool
  default     = true
}

variable "enabled_for_template_deployment" {
  description = "Whether the Key Vault can be used for template deployment"
  type        = bool
  default     = true
}

variable "enabled_for_disk_encryption" {
  description = "Whether the Key Vault can be used for disk encryption"
  type        = bool
  default     = true
}

variable "purge_protection_enabled" {
  description = "Whether purge protection is enabled"
  type        = bool
  default     = false
}

variable "soft_delete_retention_days" {
  description = "Number of days for soft delete retention"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
