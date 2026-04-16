variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "vm_resource_id" {
  description = "Full resource ID of the VM"
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

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  type        = string
}

variable "storage_account_id" {
  description = "Storage Account ID for boot diagnostics"
  type        = string
}

variable "enable_guest_monitoring" {
  description = "Enable guest-level monitoring (requires AMA agent)"
  type        = bool
  default     = false
}

variable "metrics_retention_days" {
  description = "Retention days for metrics"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
