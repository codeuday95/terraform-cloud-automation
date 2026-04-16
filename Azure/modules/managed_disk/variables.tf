variable "disk_name" {
  description = "Name of the managed disk"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "os_type" {
  description = "OS type (Windows or Linux)"
  type        = string
  default     = "Windows"
}

variable "disk_size_gb" {
  description = "Disk size in GB"
  type        = number
  default     = 64
}

variable "storage_account_type" {
  description = "Storage account type (Premium_LRS, StandardSSD_LRS, Standard_LRS)"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
