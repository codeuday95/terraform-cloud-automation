variable "automation_account_name" {
  description = "Name of the Automation Account"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "automation_location" {
  description = "Azure region for Automation Account (must be in allowed regions for Free Trial)"
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "sku_name" {
  description = "Automation Account SKU"
  type        = string
  default     = "Basic"
}

variable "vm_name" {
  description = "Name of the VM to manage"
  type        = string
}

variable "resource_group" {
  description = "Resource group containing the VM"
  type        = string
}

variable "original_vm_size" {
  description = "Original VM size (e.g., Standard_B2as_v2)"
  type        = string
  default     = "Standard_B2as_v2"
}

variable "original_disk_sku" {
  description = "Original disk SKU (e.g., StandardSSD_LRS)"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "target_vm_size" {
  description = "Target VM size for shrink operation (e.g., Standard_B2ats_v2)"
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "target_disk_sku" {
  description = "Target disk SKU for shrink operation (e.g., Standard_LRS)"
  type        = string
  default     = "Standard_LRS"
}

variable "vm_resource_id" {
  description = "Full resource ID of the VM"
  type        = string
}
