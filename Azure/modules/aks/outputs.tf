# =============================================================================
# Cluster Outputs
# =============================================================================

output "cluster_id" {
  description = "AKS cluster ID"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "kube_config_raw" {
  description = "Raw Kubernetes config"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "cluster_identity" {
  description = "Cluster identity"
  value       = azurerm_kubernetes_cluster.aks.identity
  sensitive   = false
}

# =============================================================================
# Node Pool Outputs
# =============================================================================

output "default_node_pool_name" {
  description = "Default node pool name"
  value       = azurerm_kubernetes_cluster.aks.default_node_pool[0].name
}

output "node_pool_ids" {
  description = "Map of additional node pool IDs"
  value = {
    for k, v in azurerm_kubernetes_cluster_node_pool.node_pools : k => v.id
  }
}

# =============================================================================
# Network Outputs
# =============================================================================

output "kubelet_identity_object_id" {
  description = "Object ID of kubelet identity"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "cluster_private_fqdn" {
  description = "Private FQDN of the cluster"
  value       = azurerm_kubernetes_cluster.aks.private_fqdn
}

# =============================================================================
# Monitoring Outputs
# =============================================================================

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = var.create_log_analytics_workspace && var.enable_container_insights ? azurerm_log_analytics_workspace.aks[0].id : var.existing_log_analytics_workspace_id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace name"
  value       = var.create_log_analytics_workspace && var.enable_container_insights ? azurerm_log_analytics_workspace.aks[0].name : null
}

# =============================================================================
# Identity Outputs
# =============================================================================

output "user_assigned_identity_id" {
  description = "User-assigned identity ID"
  value       = var.use_managed_identity ? null : azurerm_user_assigned_identity.aks[0].id
}

output "cluster_principal_id" {
  description = "Principal ID of cluster identity"
  value       = var.use_managed_identity ? azurerm_kubernetes_cluster.aks.identity[0].principal_id : azurerm_user_assigned_identity.aks[0].principal_id
}
