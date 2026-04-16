variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "Workload-B Service Principal Client ID (OIDC)"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "workload_name" {
  description = "Workload name"
  type        = string
  default     = "workload-b"
}

variable "tfstate_storage_account" {
  description = "Storage account name for Terraform state (from bootstrap outputs)"
  type        = string
}

variable "tfstate_resource_group" {
  description = "Resource group name for Terraform state"
  type        = string
  default     = "rg-tfstate"
}

variable "developer_ips" {
  description = "List of developer IP addresses allowed to access workload storage accounts"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Layer     = "Workload"
    Workload  = "workload-b"
  }
}

# =============================================================================
# AKS Cluster Variables
# =============================================================================

variable "enable_aks" {
  description = "Enable AKS cluster deployment"
  type        = bool
  default     = false
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-workload-b"
}

variable "aks_sku_tier" {
  description = "AKS SKU Tier (Free or Standard)"
  type        = string
  default     = "Free"
}

variable "aks_kubernetes_version" {
  description = "Kubernetes version (null = latest stable)"
  type        = string
  default     = null
}

variable "aks_default_node_pool_vm_size" {
  description = "Default node pool VM size"
  type        = string
  default     = "Standard_B2s_v2"
}

variable "aks_default_pool_autoscale_enabled" {
  description = "Enable autoscaling for default node pool"
  type        = bool
  default     = true
}

variable "aks_default_pool_min_count" {
  description = "Minimum nodes for default pool"
  type        = number
  default     = 1
}

variable "aks_default_pool_max_count" {
  description = "Maximum nodes for default pool"
  type        = number
  default     = 3
}

variable "aks_network_plugin" {
  description = "Network plugin (azure, kubenet)"
  type        = string
  default     = "azure"
}

variable "aks_enable_container_insights" {
  description = "Enable Container Insights monitoring"
  type        = bool
  default     = false
}

variable "aks_vnet_subnet_id" {
  description = "Subnet ID for AKS nodes (uses hub VNet subnet)"
  type        = string
  default     = null
}

variable "aks_create_aks_subnet" {
  description = "Create dedicated subnet for AKS in hub VNet"
  type        = bool
  default     = true
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for AKS subnet (needs /22 or larger for 500+ IPs)"
  type        = string
  default     = "10.0.128.0/20"
}
