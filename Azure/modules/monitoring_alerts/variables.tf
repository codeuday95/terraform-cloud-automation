variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "alert_name_prefix" {
  description = "Prefix for alert names (e.g., vm-win-workload-a)"
  type        = string
}

variable "vm_resource_id" {
  description = "Full resource ID of the VM"
  type        = string
}

variable "action_group_ids" {
  description = "List of action group IDs to notify"
  type        = list(string)
  default     = []
}

variable "enable_guest_monitoring" {
  description = "Enable guest-level monitoring alerts (memory, disk)"
  type        = bool
  default     = false
}

# Thresholds
variable "cpu_threshold_percent" {
  description = "CPU threshold percentage"
  type        = number
  default     = 90
}

variable "memory_threshold_mb" {
  description = "Memory threshold in MB"
  type        = number
  default     = 512
}

variable "disk_threshold_percent" {
  description = "Disk free space threshold percentage"
  type        = number
  default     = 15
}

variable "network_threshold_bytes" {
  description = "Network threshold in bytes"
  type        = number
  default     = 1073741824  # 1 GB
}
