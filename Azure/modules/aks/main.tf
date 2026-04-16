# Azure Kubernetes Service (AKS) Module

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Log Analytics Workspace for AKS monitoring (created only if enable_container_insights is true)
resource "azurerm_log_analytics_workspace" "aks" {
  count = var.enable_container_insights && var.create_log_analytics_workspace ? 1 : 0

  name                = coalesce(var.log_analytics_workspace_name, "${var.cluster_name}-law")
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_days
}

# Container Insights configuration
resource "azurerm_log_analytics_solution" "container_insights" {
  count = var.enable_container_insights && var.create_log_analytics_workspace ? 1 : 0

  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.aks[0].id
  workspace_name        = azurerm_log_analytics_workspace.aks[0].name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

# Cluster identity
resource "azurerm_user_assigned_identity" "aks" {
  count = var.use_managed_identity ? 0 : 1

  name                = "${var.cluster_name}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_role_assignment" "aks_network" {
  count = var.network_plugin == "azure" && var.create_role_assignments && var.vnet_id != null ? 1 : 0

  scope                = var.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = var.use_managed_identity ? azurerm_kubernetes_cluster.aks.identity[0].principal_id : azurerm_user_assigned_identity.aks[0].principal_id
}

resource "azurerm_role_assignment" "aks_acr" {
  for_each = toset(var.acr_ids)

  scope                = each.value
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# Azure Kubernetes Service Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = coalesce(var.dns_prefix, var.cluster_name)
  kubernetes_version  = var.kubernetes_version

  # Identity
  identity {
    type = var.use_managed_identity ? "SystemAssigned" : "UserAssigned"
    identity_ids = var.use_managed_identity ? null : [azurerm_user_assigned_identity.aks[0].id]
  }

  # Default Node Pool
  default_node_pool {
    name                   = var.default_node_pool_name
    vm_size                = var.default_node_pool_vm_size
    auto_scaling_enabled   = var.default_pool_autoscale_enabled
    min_count              = var.default_pool_autoscale_enabled ? var.default_pool_min_count : null
    max_count              = var.default_pool_autoscale_enabled ? var.default_pool_max_count : null
    node_count             = var.default_pool_autoscale_enabled ? null : var.default_pool_node_count
    orchestrator_version   = var.kubernetes_version
    os_disk_size_gb        = var.default_pool_os_disk_size
    os_disk_type           = var.default_pool_os_disk_type
    vnet_subnet_id         = var.vnet_subnet_id
    max_pods               = var.max_pods_per_node
    node_labels            = var.default_node_pool_labels
    zones                  = var.default_pool_availability_zones
    host_encryption_enabled = var.enable_host_encryption
    temporary_name_for_rotation = var.enable_host_encryption ? "tmp-${var.cluster_name}" : null
  }

  # Network Configuration
  network_profile {
    network_plugin      = var.network_plugin
    network_policy      = var.network_policy
    load_balancer_sku   = var.load_balancer_sku
    network_plugin_mode = var.network_plugin_mode
  }

  # Addon Profiles
  azure_policy_enabled = var.azure_policy_enabled

  dynamic "oms_agent" {
    for_each = var.enable_container_insights ? [1] : []
    content {
      log_analytics_workspace_id = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.aks[0].id : var.existing_log_analytics_workspace_id
    }
  }

  # Auto Upgrade Profile
  automatic_upgrade_channel = var.automatic_upgrade_channel

  # Maintenance
  maintenance_window_auto_upgrade {
    frequency     = var.maintenance_frequency
    interval      = var.maintenance_interval_weeks
    day_of_week   = var.maintenance_day_of_week
    start_time    = var.maintenance_start_time
    duration      = var.maintenance_duration
  }

  sku_tier              = var.sku_tier
  local_account_disabled = var.disable_local_account

  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
    ]
  }
}

# Node Pool (additional node pools)
resource "azurerm_kubernetes_cluster_node_pool" "node_pools" {
  for_each = var.node_pools

  name                           = each.value.name
  kubernetes_cluster_id          = azurerm_kubernetes_cluster.aks.id
  vm_size                        = each.value.vm_size
  node_count                     = each.value.node_count
  zones                          = each.value.zones
  os_disk_size_gb                = each.value.os_disk_size_gb
  os_disk_type                   = each.value.os_disk_type
  os_type                        = each.value.os_type
  vnet_subnet_id                 = each.value.vnet_subnet_id
  auto_scaling_enabled           = each.value.enable_auto_scaling
  min_count                      = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count                      = each.value.enable_auto_scaling ? each.value.max_count : null
  max_pods                       = each.value.max_pods
  node_labels                    = each.value.node_labels
  priority                       = each.value.priority
  spot_max_price                 = each.value.spot_max_price
  host_encryption_enabled        = each.value.enable_host_encryption
  capacity_reservation_group_id  = each.value.capacity_reservation_group_id
  proximity_placement_group_id   = each.value.proximity_placement_group_id
  scale_down_mode                = each.value.scale_down_mode
  tags                           = merge(var.tags, each.value.tags)

  lifecycle {
    ignore_changes = [
      node_count,
    ]
  }
}
