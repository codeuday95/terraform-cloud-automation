output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "acr_login_server" {
  description = "The Login Server URL of the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "The Admin Username for the Azure Container Registry"
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_kube_config_command" {
  description = "Command to get the kubeconfig for the AKS cluster"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${module.aks.cluster_name}"
}

output "key_vault_name" {
  description = "The name of the provisioned Azure Key Vault"
  value       = module.key_vault.name
}

output "key_vault_tenant_id" {
  description = "The Tenant ID of the Azure Key Vault"
  value       = data.azurerm_client_config.current.tenant_id
}

output "aks_kubelet_client_id" {
  description = "The Client ID of the AKS Kubelet Identity (Used for SecretProviderClass)"
  value       = module.aks.kubelet_identity_client_id
}
