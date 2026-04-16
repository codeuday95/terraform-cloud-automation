variable "subscription_id" { type = string }
variable "tenant_id" { type = string }
variable "client_id" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "organization_name" { type = string }
variable "tfstate_storage_account" { type = string }
variable "tfstate_resource_group" { type = string }

variable "platform_rg_name" {
  description = "Optional custom name for the platform resource group"
  type        = string
  default     = null
}

variable "tags" {
  description = "Base tags for all resources"
  type        = map(string)
  default     = {}
}

variable "allowed_regions" {
  description = "List of allowed regions for Azure Policy"
  type        = list(string)
  default     = ["canadacentral", "eastus", "eastus2"]
}

variable "mandatory_tags" {
  description = "List of mandatory tags for Azure Policy"
  type        = list(string)
  default     = ["Environment", "CostCenter", "Owner"]
}

variable "hub_vnet_cidr" {
  description = "CIDR block for hub Virtual Network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "hub_vnet_subnets" {
  description = "Subnets for hub VNet"
  type = map(object({
    cidr = string
  }))
  default = {
    "AzureFirewallSubnet" = { cidr = "10.0.1.0/24" }
    "GatewaySubnet"       = { cidr = "10.0.2.0/24" }
    "CoreServices"        = { cidr = "10.0.3.0/24" }
  }
}

variable "spoke_vnet_cidr" {
  description = "CIDR block for shared Spoke Virtual Network"
  type        = string
  default     = "10.1.0.0/16"
}

variable "workload_subnets" {
  description = "Subnets for workloads within the Spoke VNet"
  type = map(object({
    cidr = string
  }))
  default = {
    "workload-a" = { cidr = "10.1.1.0/24" }
    "workload-b" = { cidr = "10.1.2.0/24" }
  }
}

variable "workloads" {
  description = "Workloads to create (workload-a, workload-b, etc.)"
  type = list(object({
    name = string
    cidr = string
  }))
  default = [
    {
      name = "workload-a"
      cidr = "10.1.0.0/16"
    },
    {
      name = "workload-b"
      cidr = "10.2.0.0/16"
    }
  ]
}

variable "rbac_groups" {
  description = "Configuration for Entra ID RBAC groups"
  type = object({
    platform = object({
      admins  = string
      users   = string
      readers = string
    })
    workloads = map(object({
      admins  = string
      users   = string
      readers = string
    }))
  })
  default = {
    platform = {
      admins  = "grp-platform-dev-admins"
      users   = "grp-platform-dev-users"
      readers = "grp-platform-dev-readers"
    }
    workloads = {
      "workload-a" = {
        admins  = "grp-workload-a-dev-admins"
        users   = "grp-workload-a-dev-users"
        readers = "grp-workload-a-dev-readers"
      }
      "workload-b" = {
        admins  = "grp-workload-b-dev-admins"
        users   = "grp-workload-b-dev-users"
        readers = "grp-workload-b-dev-readers"
      }
    }
  }
}
