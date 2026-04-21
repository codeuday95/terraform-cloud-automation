data "terraform_remote_state" "platform_canadacentral" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-platform-dev-canadacentral-001"
    storage_account_name = "stplatformdevcana001"
    container_name       = "platform"
    key                  = "platform-dev.tfstate"
    use_azuread_auth     = false
  }
}

data "terraform_remote_state" "platform_westus2" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-platform-dev-westus2-001"
    storage_account_name = "stplatformdevwest001"
    container_name       = "platform"
    key                  = "platform-dev.tfstate"
    use_azuread_auth     = false
  }
}

locals {
  workload    = "workloadb"
  environment = "dev"
}

# -------------------------------------------------------------------------------------------------
# 1. Canada Central (Active) Infrastructure
# -------------------------------------------------------------------------------------------------
module "appgw_canadacentral" {
  source = "../../modules/application_gateway"

  appgw_name            = "agw-${local.workload}-${local.environment}-canadacentral-001"
  resource_group_name   = data.terraform_remote_state.platform_canadacentral.outputs.landing_zones["workload-b"].resource_group_name
  location              = data.terraform_remote_state.platform_canadacentral.outputs.landing_zones["workload-b"].resource_group_location
  create_resource_group = false
  domain_name_label     = "agw-${local.workload}-${local.environment}-canadacentral-001-dns"

  subnet_id            = data.terraform_remote_state.platform_canadacentral.outputs.hub_subnets["CoreServices"].id
  backend_ip_addresses = [module.linux_vm_canadacentral.private_ip]
  depends_on           = [azurerm_virtual_machine_extension.nginx_canadacentral]
}

module "linux_vm_canadacentral" {
  source = "../../modules/linux_vm"

  vm_name              = "vm-${local.workload}-${local.environment}-canadacentral-001"
  resource_group_name  = data.terraform_remote_state.platform_canadacentral.outputs.landing_zones["workload-b"].resource_group_name
  location             = data.terraform_remote_state.platform_canadacentral.outputs.landing_zones["workload-b"].resource_group_location
  subnet_id            = data.terraform_remote_state.platform_canadacentral.outputs.landing_zones["workload-b"].subnet_id
  
  admin_username       = "adminuser"
  admin_ssh_public_key = ""
  nsg_name             = "nsg-${local.workload}-${local.environment}-canadacentral-001"
  key_vault_id         = data.terraform_remote_state.platform_canadacentral.outputs.landing_zones["workload-b"].key_vault_id
}

resource "azurerm_virtual_machine_extension" "nginx_canadacentral" {
  name                 = "nginx-install-canadacentral"
  virtual_machine_id   = module.linux_vm_canadacentral.vm_id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"
  settings             = <<SETTINGS_EOF
  {
    "commandToExecute": "apt-get update && apt-get install -y nginx && echo 'Hello from Canada Central - Workload B' > /var/www/html/index.html && systemctl restart nginx"
  }
SETTINGS_EOF
}

# -------------------------------------------------------------------------------------------------
# 2. West US 2 (Passive/DR) Infrastructure
# -------------------------------------------------------------------------------------------------
module "appgw_westus2" {
  source = "../../modules/application_gateway"

  appgw_name            = "agw-${local.workload}-${local.environment}-westus2-001"
  resource_group_name   = data.terraform_remote_state.platform_westus2.outputs.landing_zones["workload-b"].resource_group_name
  location              = data.terraform_remote_state.platform_westus2.outputs.landing_zones["workload-b"].resource_group_location
  create_resource_group = false
  domain_name_label     = "agw-${local.workload}-${local.environment}-westus2-001-dns"

  subnet_id            = data.terraform_remote_state.platform_westus2.outputs.hub_subnets["CoreServices"].id
  backend_ip_addresses = [module.linux_vm_westus2.private_ip]
  depends_on           = [azurerm_virtual_machine_extension.nginx_westus2]
}

module "linux_vm_westus2" {
  source = "../../modules/linux_vm"

  vm_name              = "vm-${local.workload}-${local.environment}-westus2-001"
  resource_group_name  = data.terraform_remote_state.platform_westus2.outputs.landing_zones["workload-b"].resource_group_name
  location             = data.terraform_remote_state.platform_westus2.outputs.landing_zones["workload-b"].resource_group_location
  subnet_id            = data.terraform_remote_state.platform_westus2.outputs.landing_zones["workload-b"].subnet_id
  
  admin_username       = "adminuser"
  admin_ssh_public_key = ""
  nsg_name             = "nsg-${local.workload}-${local.environment}-westus2-001"
  key_vault_id         = data.terraform_remote_state.platform_westus2.outputs.landing_zones["workload-b"].key_vault_id
}

resource "azurerm_virtual_machine_extension" "nginx_westus2" {
  name                 = "nginx-install-westus2"
  virtual_machine_id   = module.linux_vm_westus2.vm_id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"
  settings             = <<SETTINGS_EOF
  {
    "commandToExecute": "apt-get update && apt-get install -y nginx && echo 'Hello from West US 2 - Workload B (DR)' > /var/www/html/index.html && systemctl restart nginx"
  }
SETTINGS_EOF
}

# -------------------------------------------------------------------------------------------------
# 3. Azure Front Door (Global Load Balancing - Active/Passive)
# -------------------------------------------------------------------------------------------------

# -------------------------------------------------------------------------------------------------
# 3. Global Routing (Azure Traffic Manager)
# -------------------------------------------------------------------------------------------------
resource "azurerm_traffic_manager_profile" "main" {
  name                   = "atm-${local.workload}-${local.environment}-global-001"
  resource_group_name    = data.terraform_remote_state.platform_canadacentral.outputs.landing_zones["workload-b"].resource_group_name
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "atm-${local.workload}-${local.environment}-global-001"
    ttl           = 100
  }

  monitor_config {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }
}

resource "azurerm_traffic_manager_azure_endpoint" "primary" {
  name               = "primary-backend"
  profile_id         = azurerm_traffic_manager_profile.main.id
  priority           = 1
  weight             = 1000
  target_resource_id = module.appgw_canadacentral.appgw_public_ip_id
}

resource "azurerm_traffic_manager_azure_endpoint" "secondary" {
  name               = "westus2-backend"
  profile_id         = azurerm_traffic_manager_profile.main.id
  priority           = 2
  weight             = 1000
  target_resource_id = module.appgw_westus2.appgw_public_ip_id
}
