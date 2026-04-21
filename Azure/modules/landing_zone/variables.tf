variable "location" {
  description = "Azure region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "workload_name" {
  description = "Workload name"
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR for the workload VNet"
  type        = string
  default     = ""
}

variable "instance" {
  description = "Instance indicator"
  type        = string
  default     = "001"
}



variable "use_hub_subnet" {
  description = "If true, use subnet from hub VNet instead of creating separate VNet"
  type        = bool
  default     = true
}

variable "hub_vnet_name" {
  description = "Name of the hub VNet (required if use_hub_subnet = true)"
  type        = string
  default     = ""
}

variable "hub_resource_group" {
  description = "Resource group name of hub VNet (required if use_hub_subnet = true)"
  type        = string
  default     = ""
}

variable "hub_subnet_name" {
  description = "Name of the hub subnet to use (required if use_hub_subnet = true)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "enable_key_vault" {
  description = "Whether to create a Key Vault"
  type        = bool
  default     = true
}

variable "enable_storage_account" {
  description = "Whether to create a Storage Account"
  type        = bool
  default     = true
}

variable "subnet_address_prefix" {
  description = "Address prefix for the workload subnet (if use_hub_subnet)"
  type        = string
  default     = ""
}
