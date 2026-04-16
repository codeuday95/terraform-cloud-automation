variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "computer_name" {
  description = "Computer name (hostname) of the VM"
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
  description = "Subnet ID for the VM"
  type        = string
}

variable "vm_size" {
  description = "VM size (e.g., Standard_B2ms)"
  type        = string
  default     = "Standard_B2ms"
}

variable "admin_username" {
  description = "Administrator username"
  type        = string
  default     = "admin"
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 64
}

variable "nsg_name" {
  description = "Name of the NSG"
  type        = string
}

variable "nic_name" {
  description = "Name of the NIC"
  type        = string
}

variable "disk_name" {
  description = "Name of the OS disk"
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
  description = "DNS label for the public IP (creates FQDN)"
  type        = string
  default     = null
}

variable "rdp_allowed_ips" {
  description = "List of IP addresses/ranges allowed for RDP access"
  type        = list(string)
  default     = ["VirtualNetwork", "Internet"]
}

variable "key_vault_id" {
  description = "Key Vault ID for storing credentials"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

variable "availability_zone" {
  description = "Availability zone for the VM"
  type        = string
  default     = "1"
}

variable "os_disk_storage_type" {
  description = "Storage account type for OS disk"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "boot_diagnostics_storage_account_id" {
  description = "Storage account ID for boot diagnostics"
  type        = string
  default     = null
}

variable "boot_diagnostics_storage_account_name" {
  description = "Storage account account name for boot diagnostics"
  type        = string
  default     = null
}
