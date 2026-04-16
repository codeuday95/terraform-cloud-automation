variable "nic_name" {
  description = "Name of the network interface"
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

variable "subnet_id" {
  description = "Subnet ID for the NIC"
  type        = string
}

variable "enable_public_ip" {
  description = "Enable public IP address"
  type        = bool
  default     = false
}

variable "public_ip_allocation_method" {
  description = "Public IP allocation method (Dynamic or Static)"
  type        = string
  default     = "Dynamic"
}

variable "domain_name_label" {
  description = "DNS label for the public IP (creates FQDN like label.region.cloudapp.azure.com)"
  type        = string
  default     = null
}

variable "nsg_id" {
  description = "Network Security Group ID to attach to the NIC"
  type        = string
  default     = ""
}

variable "attach_nsg" {
  description = "Whether to attach the NSG to this NIC"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
