variable "bastion_name" {
  description = "Name of the Azure Bastion host"
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

variable "bastion_subnet_id" {
  description = "Subnet ID for Bastion (must be named AzureBastionSubnet)"
  type        = string
}

variable "bastion_sku" {
  description = "Bastion SKU (Basic or Standard)"
  type        = string
  default     = "Basic"
}

variable "copy_paste_enabled" {
  description = "Enable copy/paste in Bastion session"
  type        = bool
  default     = true
}

variable "file_copy_enabled" {
  description = "Enable file copy in Bastion session"
  type        = bool
  default     = true
}

variable "shareable_link_enabled" {
  description = "Enable shareable link for Bastion session"
  type        = bool
  default     = false
}

variable "scale_units" {
  description = "Scale units for Bastion (affects concurrent connections)"
  type        = number
  default     = 2
}

variable "create_bastion_nsg" {
  description = "Create NSG for Bastion subnet"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
