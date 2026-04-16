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
  description = "Workload-A Service Principal Client ID (OIDC)"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "canadacentral"
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
  default     = "workload-a"
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
    Workload  = "workload-a"
  }
}

variable "enable_windows_vm" {
  description = "Enable Windows VM deployment"
  type        = bool
  default     = true
}

variable "vm_admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "admin"
}

variable "rdp_allowed_ips" {
  description = "IP ranges allowed for RDP access"
  type        = list(string)
  default     = ["VirtualNetwork", "Internet"]
}

variable "enable_public_ip" {
  description = "Enable public IP address for the VM"
  type        = bool
  default     = true
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

# DNS Zone variables
variable "enable_dns_zone" {
  description = "Enable DNS Zone for the VM"
  type        = bool
  default     = true
}

variable "dns_zone_name" {
  description = "DNS Zone name (e.g., workload-a.internal)"
  type        = string
  default     = "workload-a.internal"
}

variable "dns_record_name" {
  description = "DNS record name (e.g., vm-win-workload-a)"
  type        = string
  default     = "vm-win"
}

variable "dns_ttl" {
  description = "DNS record TTL in seconds"
  type        = number
  default     = 300
}

# Automation Account variables
variable "enable_automation" {
  description = "Enable Azure Automation Account for VM management"
  type        = bool
  default     = true
}

variable "automation_account_name" {
  description = "Name of the Automation Account"
  type        = string
  default     = "aa-vm-management"
}

variable "automation_location" {
  description = "Azure region for Automation Account (must be in allowed regions for Free Trial: eastus, eastus2, westus, etc.)"
  type        = string
  default     = null
}

variable "original_vm_size" {
  description = "Original VM size (e.g., Standard_B2as_v2)"
  type        = string
  default     = "Standard_B2as_v2"
}

variable "original_disk_sku" {
  description = "Original disk SKU (e.g., StandardSSD_LRS)"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "target_vm_size" {
  description = "Target VM size for shrink operation (e.g., Standard_B2ats_v2)"
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "target_disk_sku" {
  description = "Target disk SKU for shrink operation (e.g., Standard_LRS)"
  type        = string
  default     = "Standard_LRS"
}

# Linux VM variables
variable "enable_linux_vm" {
  description = "Enable Linux VM deployment"
  type        = bool
  default     = true
}

variable "linux_vm_size" {
  description = "Linux VM size (e.g., Standard_B2as_v2 for 2 vCPU, 4GB RAM)"
  type        = string
  default     = "Standard_B2as_v2"
}

variable "linux_admin_username" {
  description = "Admin username for Linux VM"
  type        = string
  default     = "azureuser"
}

variable "linux_admin_ssh_public_key" {
  description = "SSH public key for Linux VM"
  type        = string
  default     = ""
}

variable "linux_os_disk_storage_type" {
  description = "OS disk storage type for Linux VM"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "linux_enable_public_ip" {
  description = "Enable public IP for Linux VM"
  type        = bool
  default     = false
}

variable "linux_image_publisher" {
  description = "Linux image publisher (e.g., Canonical)"
  type        = string
  default     = "Canonical"
}

variable "linux_image_offer" {
  description = "Linux image offer"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "linux_image_sku" {
  description = "Linux image SKU"
  type        = string
  default     = "22_04-lts"
}

variable "linux_image_version" {
  description = "Linux image version"
  type        = string
  default     = "latest"
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
  default     = "aks-cluster"
}

variable "aks_sku_tier" {
  description = "AKS SKU Tier (Free or Standard)"
  type        = string
  default     = "Free"
}

variable "aks_kubernetes_version" {
  description = "Kubernetes version"
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
  description = "Enable Container Insights"
  type        = bool
  default     = true
}

variable "aks_vnet_subnet_id" {
  description = "Subnet ID for AKS nodes"
  type        = string
  default     = null
}
