variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  default     = "dev"
}

variable "workload_name" {
  description = "Workload name"
  type        = string
  default     = "wkld-d"
}

variable "vnet_address_space" {
  description = "Address space for AKS VNet"
  type        = list(string)
  default     = ["10.40.0.0/16"]
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for AKS Subnet"
  type        = string
  default     = "10.40.1.0/24"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Workload  = "wkld-d"
    Env       = "dev"
  }
}

variable "tf_sp_client_id" {
  description = "Client (application) ID of the Service Principal that runs Terraform and should be granted Key Vault secret permissions"
  type        = string
  sensitive   = true
  default     = ""
}
