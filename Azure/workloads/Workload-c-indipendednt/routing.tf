resource "random_string" "global" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_network_security_group" "appgw_primary" {
  name                = "nsg-appgw-pri"
  location            = module.rg_primary.location
  resource_group_name = module.rg_primary.name

  security_rule {
    name                       = "AllowFrontDoorInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowGatewayManagerInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "appgw_primary" {
  subnet_id                 = module.vnet_primary.subnets["snet-appgw"].id
  network_security_group_id = azurerm_network_security_group.appgw_primary.id
}

resource "azurerm_network_security_group" "appgw_secondary" {
  name                = "nsg-appgw-sec"
  location            = module.rg_secondary.location
  resource_group_name = module.rg_secondary.name

  security_rule {
    name                       = "AllowFrontDoorInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowGatewayManagerInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "appgw_secondary" {
  subnet_id                 = module.vnet_secondary.subnets["snet-appgw"].id
  network_security_group_id = azurerm_network_security_group.appgw_secondary.id
}

module "appgw_primary" {
  source              = "../../modules/application_gateway"
  appgw_name          = "agw-${var.workload_name}-${var.primary_location}"
  resource_group_name = module.rg_primary.name
  location            = module.rg_primary.location
  subnet_id           = module.vnet_primary.subnets["snet-appgw"].id
  backend_pool_name   = "pool-appgw-primary"
  sku_name            = "Standard_v2"
  sku_tier            = "Standard_v2"
  capacity            = 1
  enable_autoscale    = false
  domain_name_label   = "workloadc-eastus-4pn74n"
  tags                = var.tags
  
  depends_on = [module.rg_primary]
}

module "appgw_secondary" {
  source              = "../../modules/application_gateway"
  appgw_name          = "agw-${var.workload_name}-${var.secondary_location}"
  resource_group_name = module.rg_secondary.name
  location            = module.rg_secondary.location
  subnet_id           = module.vnet_secondary.subnets["snet-appgw"].id
  backend_pool_name   = "pool-appgw-secondary"
  sku_name            = "Standard_v2"
  sku_tier            = "Standard_v2"
  capacity            = 1
  enable_autoscale    = false
  domain_name_label   = "workloadc-westus-4pn74n"
  tags                = var.tags

  depends_on = [module.rg_secondary]
}
module "front_door" {
  source              = "../../modules/front_door"
  frontdoor_name      = "fd-${var.workload_name}-${random_string.global.result}"
  resource_group_name = module.rg_primary.name
  primary_backend_address = "workloadc-eastus-4pn74n.eastus.cloudapp.azure.com"
  secondary_backends = [
    {
      name    = "secondary"
      address = "workloadc-westus-4pn74n.westus.cloudapp.azure.com"
    }
  ]
  route_forwarding_protocol = "HttpOnly"
  origin_host_header        = null # Will default to backend address
  health_probe_protocol     = "Http"
  health_probe_method       = "GET"
  tags                      = var.tags

  depends_on = [module.rg_primary, module.appgw_primary, module.appgw_secondary]
}
