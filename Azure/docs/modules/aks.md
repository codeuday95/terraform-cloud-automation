# AKS Module

Azure Kubernetes Service (AKS) module with Azure CNI networking.

## Usage

```hcl
module "aks" {
  source = "../../modules/aks"

  cluster_name        = "my-aks-cluster"
  location            = "canadacentral"
  resource_group_name = "rg-my-app"

  # Node Pool
  default_node_pool_vm_size      = "Standard_B2s_v2"
  default_pool_autoscale_enabled = true
  default_pool_min_count         = 1
  default_pool_max_count         = 3

  # Network
  network_plugin = "azure"
  vnet_subnet_id = "/subscriptions/.../subnet-aks"

  # Optional monitoring
  enable_container_insights = false
}
```

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| `cluster_name` | AKS cluster name | - |
| `location` | Azure region | - |
| `resource_group_name` | Resource group name | - |
| `sku_tier` | Free or Standard | `"Free"` |
| `default_node_pool_vm_size` | VM size for nodes | `"Standard_B2s_v2"` |
| `default_pool_autoscale_enabled` | Enable autoscaling | `true` |
| `default_pool_min_count` | Minimum nodes | `1` |
| `default_pool_max_count` | Maximum nodes | `3` |
| `network_plugin` | azure or kubenet | `"azure"` |
| `enable_container_insights` | Enable monitoring | `false` |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | AKS cluster ID |
| `cluster_name` | AKS cluster name |
| `cluster_fqdn` | Cluster FQDN |
| `kube_config_raw` | Kubeconfig (sensitive) |
| `log_analytics_workspace_id` | LAW ID if enabled |

## Features

- [x] Azure CNI networking
- [x] Autoscaling node pool
- [x] Multi-zone deployment
- [x] Optional Container Insights
- [x] Free/Standard tier support
- [x] ACR integration
- [x] Maintenance windows

## Notes

- Container Insights is disabled by default
- Uses SystemAssigned managed identity
- Default maintenance window: Sunday 02:00 (4 hours)

