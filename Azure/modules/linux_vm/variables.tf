variable "vm_name" {
  description = "Name of the Linux VM"
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

variable "nsg_name" {
  description = "Name of the NSG to create"
  type        = string
}

variable "ssh_allowed_ips" {
  description = "List of IP addresses allowed for SSH"
  type        = list(string)
  default     = ["VirtualNetwork", "Internet"]
}

variable "subnet_id" {
  description = "Subnet ID for the VM"
  type        = string
}

variable "vm_size" {
  description = "VM size (e.g., Standard_B2as_v2)"
  type        = string
  default     = "Standard_B2as_v2"
}

variable "admin_username" {
  description = "Admin username"
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  description = "SSH public key"
  type        = string
}

variable "os_disk_storage_account_type" {
  description = "OS disk storage account type"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "enable_public_ip" {
  description = "Enable public IP"
  type        = bool
  default     = false
}

variable "nsg_id" {
  description = "Network Security Group ID"
  type        = string
  default     = ""
}

variable "attach_nsg" {
  description = "Whether to attach an NSG to the Linux VM NIC"
  type        = bool
  default     = false
}

variable "enable_boot_diagnostics" {
  description = "Enable boot diagnostics"
  type        = bool
  default     = false
}

variable "boot_diagnostics_storage_account_uri" {
  description = "Storage account URI for boot diagnostics"
  type        = string
  default     = null
}

variable "source_image_publisher" {
  description = "Source image publisher"
  type        = string
  default     = "Canonical"
}

variable "source_image_offer" {
  description = "Source image offer"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "source_image_sku" {
  description = "Source image SKU"
  type        = string
  default     = "22_04-lts"
}

variable "source_image_version" {
  description = "Source image version"
  type        = string
  default     = "latest"
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

variable "key_vault_id" {
  description = "The ID of the Key Vault where the VM credentials will be stored"
  type        = string
}
