output "workload_rg_name" {
  description = "Workload Resource Group name"
  value       = data.terraform_remote_state.platform.outputs.workload_resource_groups[var.workload_name].name
}

output "workload_rg_id" {
  description = "Workload Resource Group ID"
  value       = data.terraform_remote_state.platform.outputs.workload_resource_groups[var.workload_name].id
}

output "tfstate_storage_account_name" {
  description = "Workload Terraform state storage account name"
  value       = module.tfstate_storage.storage_account_name
}

output "tfstate_storage_account_id" {
  description = "Workload Terraform state storage account ID"
  value       = module.tfstate_storage.storage_account_id
}

output "tfstate_container_name" {
  description = "Workload Terraform state container name"
  value       = module.tfstate_storage.container_name
}

output "app_service_id" {
  description = "App Service ID"
  value       = azurerm_linux_web_app.workload_b.id
}

output "app_service_url" {
  description = "App Service URL"
  value       = azurerm_linux_web_app.workload_b.default_hostname
}

output "container_registry_id" {
  description = "Container Registry ID"
  value       = azurerm_container_registry.workload_b.id
}

output "container_registry_login_server" {
  description = "Container Registry login server"
  value       = azurerm_container_registry.workload_b.login_server
}

output "cosmos_db_id" {
  description = "Cosmos DB Account ID"
  value       = azurerm_cosmosdb_account.workload_b.id
}

output "cosmos_db_endpoint" {
  description = "Cosmos DB Account endpoint"
  value       = azurerm_cosmosdb_account.workload_b.endpoint
}
