output "workload_rg_name" {
  description = "Workload Resource Group name"
  value       = data.terraform_remote_state.platform.outputs.workload_resource_groups[var.workload_name].name
}

output "workload_rg_id" {
  description = "Workload Resource Group ID"
  value       = data.terraform_remote_state.platform.outputs.workload_resource_groups[var.workload_name].id
}

output "windows_vm_name" {
  description = "Windows VM name"
  value       = module.windows_vm[0].vm_name
}

output "windows_vm_private_ip" {
  description = "Windows VM private IP"
  value       = module.windows_vm[0].private_ip_address
}

output "windows_vm_public_ip" {
  description = "Windows VM public IP"
  value       = module.windows_vm[0].public_ip_address
}

output "windows_vm_admin_username" {
  description = "Windows VM admin username"
  value       = module.windows_vm[0].admin_username
  sensitive   = true
}

output "dns_zone_name" {
  description = "DNS Zone name"
  value       = module.dns_zone[0].dns_zone_name
}

output "dns_record_fqdn" {
  description = "DNS record FQDN"
  value       = module.dns_zone[0].dns_record_fqdn
}

output "name_servers" {
  description = "DNS Name Servers"
  value       = module.dns_zone[0].name_servers
}

# Automation Account Outputs
output "automation_account_name" {
  description = "Name of the Automation Account"
  value       = length(module.automation_account) > 0 ? module.automation_account[0].automation_account_name : null
}

output "automation_account_id" {
  description = "ID of the Automation Account"
  value       = length(module.automation_account) > 0 ? module.automation_account[0].automation_account_id : null
}

output "automation_managed_identity_principal_id" {
  description = "The Principal ID of the Automation Account's System Assigned Managed Identity"
  value       = length(module.automation_account) > 0 ? module.automation_account[0].managed_identity_principal_id : null
}
