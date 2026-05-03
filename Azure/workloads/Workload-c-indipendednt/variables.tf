variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}



variable "primary_location" {
  description = "Primary Azure region"
  type        = string
  default     = "eastus"
}

variable "secondary_location" {
  description = "Secondary Azure region for DR"
  type        = string
  default     = "westus"
}

variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  default     = "dev"
}

variable "workload_name" {
  description = "Workload name"
  type        = string
  default     = "workloadc"
}

variable "vnet_primary_address_space" {
  description = "Address space for Primary VNet"
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "vnet_secondary_address_space" {
  description = "Address space for Secondary VNet"
  type        = list(string)
  default     = ["10.20.0.0/16"]
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Workload  = "workload-c"
    Env       = "dev"
  }
}

variable "create_hub" {
  description = "Create a new Hub VNet or use an existing one"
  type        = bool
  default     = true
}

variable "hub_vnet_name" {
  description = "Name of the existing or new Hub VNet"
  type        = string
  default     = "vnet-hub-eastus"
}

variable "hub_resource_group_name" {
  description = "Resource Group for the Hub VNet"
  type        = string
  default     = "rg-hub-eastus"
}

variable "hub_vnet_address_space" {
  description = "Address space for Hub VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}
