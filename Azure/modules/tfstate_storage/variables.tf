variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique, lowercase alphanumeric only)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the storage account"
  type        = string
}

variable "container_name" {
  description = "Name of the storage container for tfstate"
  type        = string
  default     = "tfstate"
}

variable "account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "Replication type (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)"
  type        = string
  default     = "GRS"  # Geographically redundant for critical state
}

variable "allowed_ip_ranges" {
  description = "List of IP addresses/ranges allowed to access the storage account"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access the storage account"
  type        = list(string)
  default     = []
}

variable "enable_public_access" {
  description = "Whether to enable public access (set to false for production)"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable versioning for recovery from accidental deletes"
  type        = bool
  default     = true
}

variable "soft_delete_days" {
  description = "Number of days to retain soft-deleted blobs"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
