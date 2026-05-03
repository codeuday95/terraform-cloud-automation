variable "vault_name" {
  description = "Name of the Recovery Services Vault"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "sku" {
  description = "SKU type (Standard or RS0)"
  type        = string
  default     = "Standard"
}

variable "soft_delete_enabled" {
  description = "Enable soft delete protection"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention period (14-180 days)"
  type        = number
  default     = 14
}

variable "storage_redundancy" {
  description = "Storage redundancy (LocallyRedundant, GeoRedundant, ZoneRedundant)"
  type        = string
  default     = "LocallyRedundant"
}

# Backup Policy
variable "backup_policy_name" {
  description = "Name of the backup policy"
  type        = string
  default     = "default-vm-backup-policy"
}

variable "backup_time" {
  description = "Backup time in UTC (HH:MM format)"
  type        = string
  default     = "23:00"
}

variable "backup_timezone" {
  description = "Timezone for backup schedule"
  type        = string
  default     = "UTC"
}

variable "daily_retention_days" {
  description = "Number of days to retain daily backups"
  type        = number
  default     = 7
}

variable "weekly_retention_weeks" {
  description = "Number of weeks to retain weekly backups"
  type        = number
  default     = 4
}

variable "monthly_retention_months" {
  description = "Number of months to retain monthly backups (0 to disable)"
  type        = number
  default     = 0
}

variable "instant_rp_recovery_days" {
  description = "Instant restore point recovery range in days"
  type        = number
  default     = 5
}

variable "instant_rp_enabled" {
  description = "Enable instant restore points"
  type        = bool
  default     = true
}

variable "create_backup_resource_group" {
  description = "Create a dedicated resource group for backup storage"
  type        = bool
  default     = false
}

variable "backup_resource_group_name" {
  description = "Name of backup resource group"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

variable "identity_type" {
  description = "Type of Managed Identity"
  type        = string
  default     = "SystemAssigned"
}
