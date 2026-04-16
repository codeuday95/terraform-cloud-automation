variable "nsg_name" {
  description = "Name of the NSG"
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

variable "rdp_allowed_ips" {
  description = "List of IP addresses/ranges allowed for RDP/SSH access"
  type        = list(string)
  default     = ["VirtualNetwork", "Internet"]
}

variable "inbound_port" {
  description = "Port to allow inbound (e.g. 3389 for RDP, 22 for SSH)"
  type        = string
  default     = "3389"
}

variable "inbound_rule_name" {
  description = "Name of the inbound rule"
  type        = string
  default     = "AllowRDP"
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
