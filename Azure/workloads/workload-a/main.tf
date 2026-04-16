# Get workload resource group name and subnet from platform outputs
data "terraform_remote_state" "platform" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-platform-${var.environment}-tfstate"
    storage_account_name = "stnuautomationplcanadev"
    container_name       = "platform"
    key                  = "platform-dev.tfstate"
    use_azuread_auth     = true
  }
}

# =============================================================================
# Windows VM Deployment
# Uses existing subnet from platform's hub VNet
# =============================================================================

# Windows VM - uses platform's hub subnet directly
module "windows_vm" {
  count = var.enable_windows_vm ? 1 : 0

  source = "../../modules/windows_vm"

  vm_name                               = "vm-win-${var.workload_name}-${var.environment}-01"
  computer_name                         = "WIN${var.environment}01"
  location                              = var.location
  resource_group_name                   = data.terraform_remote_state.platform.outputs.workload_resource_groups[var.workload_name].name
  subnet_id                             = data.terraform_remote_state.platform.outputs.workload_subnets[var.workload_name].id
  vm_size                               = "Standard_B2as_v2"
  availability_zone                     = "1"
  os_disk_storage_type                  = "StandardSSD_LRS"
  admin_username                        = var.vm_admin_username
  os_disk_size_gb                       = 64
  nsg_name                              = "nsg-${var.workload_name}-${var.environment}"
  nic_name                              = "nic-${var.workload_name}-${var.environment}-01"
  disk_name                             = "disk-${var.workload_name}-${var.environment}-os"
  enable_public_ip                      = var.enable_public_ip
  public_ip_allocation_method           = var.public_ip_allocation_method
  rdp_allowed_ips                       = var.rdp_allowed_ips
  key_vault_id                          = data.terraform_remote_state.platform.outputs.workload_keyvaults[var.workload_name].id
  boot_diagnostics_storage_account_id   = data.terraform_remote_state.platform.outputs.workload_storage_accounts[var.workload_name].id
  boot_diagnostics_storage_account_name = data.terraform_remote_state.platform.outputs.workload_storage_accounts[var.workload_name].name

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Workload    = var.workload_name
      Purpose     = "Windows VM"
    }
  )

  depends_on = [
    data.terraform_remote_state.platform
  ]
}

# =============================================================================
# DNS Zone for VM
# =============================================================================

module "dns_zone" {
  count = var.enable_dns_zone ? 1 : 0

  source = "../../modules/dns_zone"

  dns_zone_name       = var.dns_zone_name
  resource_group_name = data.terraform_remote_state.platform.outputs.workload_resource_groups[var.workload_name].name
  record_name         = var.dns_record_name
  vm_public_ip        = module.windows_vm[0].public_ip_address
  ttl                 = var.dns_ttl
}

# =============================================================================
# Azure Automation Account for VM Management
# =============================================================================

module "automation_account" {
  count = var.enable_automation ? 1 : 0

  source = "../../modules/automation_account"

  automation_account_name = var.automation_account_name
  location                = var.location
  automation_location     = var.automation_location
  resource_group_name     = data.terraform_remote_state.platform.outputs.workload_resource_groups[var.workload_name].name
  vm_name                 = "vm-win-${var.workload_name}-${var.environment}-01"
  resource_group          = data.terraform_remote_state.platform.outputs.workload_resource_groups[var.workload_name].name
  original_vm_size        = var.original_vm_size
  original_disk_sku       = var.original_disk_sku
  target_vm_size          = var.target_vm_size
  target_disk_sku         = var.target_disk_sku
  vm_resource_id          = "/subscriptions/${var.subscription_id}/resourceGroups/${data.terraform_remote_state.platform.outputs.workload_resource_groups[var.workload_name].name}/providers/Microsoft.Compute/virtualMachines/vm-win-${var.workload_name}-${var.environment}-01"
}

# =============================================================================
# Linux VM Deployment
# Uses existing subnet from platform's hub VNet
# =============================================================================

module "linux_vm" {
  count = var.enable_linux_vm ? 1 : 0

  source = "../../modules/linux_vm"

  vm_name                      = "vm-linux-${var.workload_name}-${var.environment}-01"
  location                     = var.location
  resource_group_name          = data.terraform_remote_state.platform.outputs.workload_resource_groups[var.workload_name].name
  subnet_id                    = data.terraform_remote_state.platform.outputs.workload_subnets[var.workload_name].id
  vm_size                      = var.linux_vm_size
  admin_username               = var.linux_admin_username
  admin_ssh_public_key         = var.linux_admin_ssh_public_key
  key_vault_id                 = data.terraform_remote_state.platform.outputs.workload_keyvaults[var.workload_name].id
  os_disk_storage_account_type = var.linux_os_disk_storage_type
  enable_public_ip             = var.linux_enable_public_ip

  nsg_name        = "nsg-linux-${var.workload_name}-${var.environment}"
  ssh_allowed_ips = var.rdp_allowed_ips
  attach_nsg      = true

  enable_boot_diagnostics              = true
  boot_diagnostics_storage_account_uri = "https://${data.terraform_remote_state.platform.outputs.workload_storage_accounts[var.workload_name].name}.blob.core.windows.net/"

  source_image_publisher = var.linux_image_publisher
  source_image_offer     = var.linux_image_offer
  source_image_sku       = var.linux_image_sku
  source_image_version   = var.linux_image_version

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Workload    = var.workload_name
      Purpose     = "Linux VM"
    }
  )

  depends_on = [
    data.terraform_remote_state.platform
  ]
}

# =============================================================================
# AKS Cluster Deployment
# =============================================================================

module "aks" {
  count = var.enable_aks ? 1 : 0

  source = "../../modules/aks"

  cluster_name        = "aks-${var.workload_name}-${var.environment}-01"
  location            = var.location
  resource_group_name = data.terraform_remote_state.platform.outputs.workload_resource_groups[var.workload_name].name

  # Cluster Configuration
  kubernetes_version = var.aks_kubernetes_version
  sku_tier           = var.aks_sku_tier

  # Default Node Pool
  default_node_pool_vm_size      = var.aks_default_node_pool_vm_size
  default_pool_autoscale_enabled = var.aks_default_pool_autoscale_enabled
  default_pool_min_count         = var.aks_default_pool_min_count
  default_pool_max_count         = var.aks_default_pool_max_count

  # Network Configuration
  network_plugin = var.aks_network_plugin
  network_policy = "azure"
  vnet_subnet_id = var.aks_vnet_subnet_id != null ? var.aks_vnet_subnet_id : data.terraform_remote_state.platform.outputs.workload_subnets[var.workload_name].id

  # Monitoring
  enable_container_insights = var.aks_enable_container_insights

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Workload    = var.workload_name
      Purpose     = "AKS Cluster"
    }
  )

  depends_on = [
    data.terraform_remote_state.platform
  ]
}
