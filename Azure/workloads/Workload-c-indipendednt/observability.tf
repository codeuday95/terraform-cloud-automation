module "law" {
  source              = "../../modules/log_analytics_workspace"
  workspace_name      = "law-${var.workload_name}-${random_string.global.result}"
  location            = module.rg_primary.location
  resource_group_name = module.rg_primary.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}


resource "azurerm_monitor_diagnostic_setting" "appgw_primary" {
  name                       = "diag-appgw-pri"
  target_resource_id         = module.appgw_primary.appgw_id
  log_analytics_workspace_id = module.law.workspace_id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }
  
  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }
  
  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "sql_primary" {
  name                       = "diag-sql-pri"
  target_resource_id         = module.sql_primary.database_id
  log_analytics_workspace_id = module.law.workspace_id

  enabled_log {
    category = "SQLSecurityAuditEvents"
  }
  
  metric {
    category = "Basic"
    enabled  = true
  }
}
