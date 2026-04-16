# Azure Monitor Alerts for VM
# Creates alert rules for CPU, Memory, Disk, and VM State

# Alert: High CPU Usage
resource "azurerm_monitor_scheduled_query_rule_alertv2" "high_cpu" {
  name                = "alert-${var.alert_name_prefix}-high-cpu"
  resource_group_name = var.resource_group_name
  location            = var.location
  evaluation_frequency = "PT1M"
  window_duration      = "PT5M"
  severity             = 3
  auto_mitigation_enabled = true
  enabled              = true

  query = <<-QUERY
    AzureMetrics
    | where ResourceId =~ "${var.vm_resource_id}"
    | where MetricName == "Percentage CPU"
    | summarize AggregatedValue = avg(Average) by Resource, bin(TimeGenerated, 5m)
    | where AggregatedValue > ${var.cpu_threshold_percent}
  QUERY

  criteria {
    operator             = "Greater"
    threshold            = var.cpu_threshold_percent
    failing_periods_count = 1
    metric_dimension {
      name     = "ResourceId"
      operator = "Include"
      values   = [var.vm_resource_id]
    }
  }

  action_groups = var.action_group_ids
}

# Alert: Low Available Memory (requires Guest-level monitoring)
resource "azurerm_monitor_scheduled_query_rule_alertv2" "low_memory" {
  count               = var.enable_guest_monitoring ? 1 : 0
  name                = "alert-${var.alert_name_prefix}-low-memory"
  resource_group_name = var.resource_group_name
  location            = var.location
  evaluation_frequency = "PT1M"
  window_duration      = "PT5M"
  severity             = 3
  auto_mitigation_enabled = true
  enabled              = true

  query = <<-QUERY
    InsightsMetrics
    | where Origin == "vm.azm.onmicrosoft.com"
    | where Name == "AvailableMB"
    | where ResourceId =~ "${var.vm_resource_id}"
    | summarize AggregatedValue = avg(Val) by Resource, bin(TimeGenerated, 5m)
    | where AggregatedValue < ${var.memory_threshold_mb}
  QUERY

  criteria {
    operator             = "Less"
    threshold            = var.memory_threshold_mb
    failing_periods_count = 1
  }

  action_groups = var.action_group_ids
}

# Alert: Low Disk Space
resource "azurerm_monitor_scheduled_query_rule_alertv2" "low_disk" {
  count               = var.enable_guest_monitoring ? 1 : 0
  name                = "alert-${var.alert_name_prefix}-low-disk"
  resource_group_name = var.resource_group_name
  location            = var.location
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  severity             = 2
  auto_mitigation_enabled = true
  enabled              = true

  query = <<-QUERY
    InsightsMetrics
    | where Origin == "vm.azm.onmicrosoft.com"
    | where Name == "FreeSpacePercentage"
    | where ResourceId =~ "${var.vm_resource_id}"
    | summarize AggregatedValue = avg(Val) by Resource, bin(TimeGenerated, 15m)
    | where AggregatedValue < ${var.disk_threshold_percent}
  QUERY

  criteria {
    operator             = "Less"
    threshold            = var.disk_threshold_percent
    failing_periods_count = 1
  }

  action_groups = var.action_group_ids
}

# Alert: VM Deallocated/Stopped
resource "azurerm_monitor_scheduled_query_rule_alertv2" "vm_deallocated" {
  name                = "alert-${var.alert_name_prefix}-vm-stopped"
  resource_group_name = var.resource_group_name
  location            = var.location
  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"
  severity             = 1
  auto_mitigation_enabled = false
  enabled              = true

  query = <<-QUERY
    AzureDiagnostics
    | where ResourceId =~ "${var.vm_resource_id}"
    | where Category == "Administrative"
    | where OperationName_value == "delete virtualMachine" or OperationName_value == "stop virtualMachine"
    | project TimeGenerated, Resource, OperationName, ResultSignature
  QUERY

  criteria {
    operator             = "Greater"
    threshold            = 0
    failing_periods_count = 1
  }

  action_groups = var.action_group_ids
}

# Alert: High Network In
resource "azurerm_monitor_scheduled_query_rule_alertv2" "high_network_in" {
  name                = "alert-${var.alert_name_prefix}-high-network-in"
  resource_group_name = var.resource_group_name
  location            = var.location
  evaluation_frequency = "PT1M"
  window_duration      = "PT5M"
  severity             = 4
  auto_mitigation_enabled = true
  enabled              = false  # Disabled by default

  query = <<-QUERY
    AzureMetrics
    | where ResourceId =~ "${var.vm_resource_id}"
    | where MetricName == "Network In"
    | summarize AggregatedValue = sum(Average) by Resource, bin(TimeGenerated, 5m)
    | where AggregatedValue > ${var.network_threshold_bytes}
  QUERY

  criteria {
    operator             = "Greater"
    threshold            = var.network_threshold_bytes
    failing_periods_count = 1
  }

  action_groups = var.action_group_ids
}
