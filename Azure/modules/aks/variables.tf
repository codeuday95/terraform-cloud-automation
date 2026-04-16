# =============================================================================
# Required Variables
# =============================================================================

variable "cluster_name" {
  description = "Name of the AKS cluster"
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

# =============================================================================
# Cluster Configuration
# =============================================================================

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = null
}

variable "dns_prefix" {
  description = "DNS prefix for the cluster"
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "SKU Tier (Free or Standard)"
  type        = string
  default     = "Free"
}

variable "disable_local_account" {
  description = "Disable local Kubernetes account"
  type        = bool
  default     = false
}

# =============================================================================
# Identity Configuration
# =============================================================================

variable "use_managed_identity" {
  description = "Use managed identity for the cluster"
  type        = bool
  default     = true
}

# =============================================================================
# Default Node Pool Configuration
# =============================================================================

variable "default_node_pool_name" {
  description = "Name of the default node pool"
  type        = string
  default     = "nodepool1"
}

variable "default_node_pool_vm_size" {
  description = "VM size for the default node pool"
  type        = string
  default     = "Standard_B2s_v2"
}

variable "default_node_pool_labels" {
  description = "Labels for the default node pool"
  type        = map(string)
  default     = {}
}

variable "default_node_pool_taints" {
  description = "Taints for the default node pool"
  type        = list(string)
  default     = []
}

variable "default_pool_autoscale_enabled" {
  description = "Enable autoscaling for default node pool"
  type        = bool
  default     = true
}

variable "default_pool_min_count" {
  description = "Minimum nodes for default pool autoscaling"
  type        = number
  default     = 1
}

variable "default_pool_max_count" {
  description = "Maximum nodes for default pool autoscaling"
  type        = number
  default     = 3
}

variable "default_pool_node_count" {
  description = "Node count for default pool (when autoscaling disabled)"
  type        = number
  default     = 2
}

variable "default_pool_os_disk_size" {
  description = "OS disk size for default node pool (GB)"
  type        = number
  default     = 128
}

variable "default_pool_os_disk_type" {
  description = "OS disk type for default node pool"
  type        = string
  default     = "Managed"
}

variable "default_pool_availability_zones" {
  description = "Availability zones for default node pool"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "enable_host_encryption" {
  description = "Enable host encryption for default node pool"
  type        = bool
  default     = false
}

# =============================================================================
# Network Configuration
# =============================================================================

variable "network_plugin" {
  description = "Network plugin (azure, kubenet, none)"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy (azure, calico, none)"
  type        = string
  default     = "azure"
}

variable "network_plugin_mode" {
  description = "Network plugin mode (overlay, transparent)"
  type        = string
  default     = null
}

variable "load_balancer_sku" {
  description = "Load balancer SKU (standard, basic)"
  type        = string
  default     = "standard"
}

variable "vnet_subnet_id" {
  description = "Subnet ID for AKS nodes"
  type        = string
  default     = null
}

variable "vnet_id" {
  description = "VNet ID for role assignment"
  type        = string
  default     = null
}

variable "max_pods_per_node" {
  description = "Maximum pods per node"
  type        = number
  default     = 30
}

# =============================================================================
# Additional Node Pools
# =============================================================================

variable "node_pools" {
  description = "Map of additional node pools"
  type = map(object({
    name                          = string
    vm_size                       = string
    node_count                    = number
    zones                         = list(string)
    os_disk_size_gb               = number
    os_disk_type                  = string
    os_type                       = string
    vnet_subnet_id                = string
    enable_auto_scaling           = bool
    min_count                     = number
    max_count                     = number
    max_pods                      = number
    node_labels                   = map(string)
    node_taints                   = list(string)
    priority                      = string
    spot_max_price                = number
    enable_host_encryption        = bool
    capacity_reservation_group_id = string
    proximity_placement_group_id  = string
    scale_down_mode               = string
    tags                          = map(string)
  }))
  default = {}
}

# =============================================================================
# Monitoring & Logging
# =============================================================================

variable "create_log_analytics_workspace" {
  description = "Create a new Log Analytics workspace"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_name" {
  description = "Name of Log Analytics workspace"
  type        = string
  default     = null
}

variable "log_analytics_sku" {
  description = "SKU of Log Analytics workspace"
  type        = string
  default     = "PerGB2018"
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

variable "enable_container_insights" {
  description = "Enable Container Insights"
  type        = bool
  default     = true
}

variable "existing_log_analytics_workspace_id" {
  description = "Existing Log Analytics workspace ID"
  type        = string
  default     = null
}

variable "azure_policy_enabled" {
  description = "Enable Azure Policy addon"
  type        = bool
  default     = true
}

# =============================================================================
# Maintenance & Upgrades
# =============================================================================

variable "automatic_upgrade_channel" {
  description = "Automatic upgrade channel (stable, rapid, patch, node-image, none)"
  type        = string
  default     = "patch"
}

variable "maintenance_frequency" {
  description = "Maintenance frequency (Weekly, Monthly, Relative, Daily)"
  type        = string
  default     = "Weekly"
}

variable "maintenance_interval_weeks" {
  description = "Maintenance interval in weeks"
  type        = number
  default     = 1
}

variable "maintenance_day_of_week" {
  description = "Day of week for maintenance"
  type        = string
  default     = "Sunday"
}

variable "maintenance_start_time" {
  description = "Maintenance start time (HH:MM)"
  type        = string
  default     = "02:00"
}

variable "maintenance_duration" {
  description = "Maintenance duration in hours"
  type        = number
  default     = 4
}

# =============================================================================
# ACR Integration
# =============================================================================

variable "acr_ids" {
  description = "List of ACR resource IDs to grant pull access"
  type        = list(string)
  default     = []
}

# =============================================================================
# Tags
# =============================================================================

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "create_role_assignments" {
  description = "Create role assignments for network contributor"
  type        = bool
  default     = true
}
