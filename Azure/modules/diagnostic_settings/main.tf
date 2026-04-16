# Diagnostic Settings for VM
# Sends boot logs, event logs, and performance counters to Log Analytics

# Diagnostic Settings for VM (Boot logs + Guest-level logs)
resource "azurerm_monitor_diagnostic_setting" "vm_diagnostics" {
  name                       = "diag-${var.vm_name}"
  target_resource_id         = var.vm_resource_id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  # Boot Diagnostics Logs
  enabled_log {
    category = "BootDiagnostic"
  }

  # Guest-level logs (requires Azure Monitor Agent)
  enabled_log {
    category = "GuestLogs"
  }

  # Performance counters
  metric {
    category = "AllMetrics"
    enabled  = true
    retention_policy {
      enabled = true
      days    = var.metrics_retention_days
    }
  }

  depends_on = [
    azurerm_monitor_diagnostic_setting.boot_diagnostics
  ]
}

# Boot Diagnostics Storage (separate from logs)
resource "azurerm_monitor_diagnostic_setting" "boot_diagnostics" {
  name                       = "bootdiag-${var.vm_name}"
  target_resource_id         = var.vm_resource_id
  storage_account_id         = var.storage_account_id

  enabled_log {
    category = "BootDiagnostic"
  }

  metric {
    category = "AllMetrics"
    enabled  = false
  }
}

# Azure Monitor Agent (AMA) Configuration for Guest-level monitoring
resource "azurerm_monitor_data_collection_rule" "vm_logs" {
  count               = var.enable_guest_monitoring ? 1 : 0
  name                = "dcr-${var.vm_name}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name

  destinations {
    log_analytics {
      name                  = "logs-destination"
      workspace_resource_id = var.log_analytics_workspace_id
    }
  }

  data_flow {
    streams      = ["Microsoft-Event", "Microsoft-PerformanceCounters"]
    destinations = ["logs-destination"]
  }

  data_sources {
    performance_counter {
      name                        = "perfCounters"
      streams                     = ["Microsoft-PerformanceCounters"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor Information(_Total)\\% Processor Time",
        "\\Memory\\Available MBytes",
        "\\LogicalDisk(_Total)\\% Free Space",
        "\\Network Interface(*)\\Bytes Total/sec"
      ]
    }

    event_log {
      name    = "eventLogs"
      streams = ["Microsoft-Event"]
      x_path  = "Application!*[System[(Level=1 or Level=2 or Level=3)]]"
    }
  }
}

# Associate DCR with VM
resource "azurerm_monitor_data_collection_rule_association" "vm_association" {
  count                   = var.enable_guest_monitoring ? 1 : 0
  name                    = "dcr-assoc-${var.vm_name}"
  target_resource_id      = var.vm_resource_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_logs[0].id
}
