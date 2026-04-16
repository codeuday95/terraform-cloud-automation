# Azure Budget and Cost Alerts

resource "azurerm_consumption_budget" "workload_budget" {
  name              = "budget-${var.budget_name}"
  resource_group_id = var.resource_group_id
  amount            = var.budget_amount
  time_grain        = var.time_grain  # Monthly, Quarterly, Annually

  time_period {
    start_date = var.budget_start_date  # Format: YYYY-MM-DD
    end_date   = var.budget_end_date    # Format: YYYY-MM-DD (null for ongoing)
  }

  dynamic "notification" {
    for_each = var.notifications
    content {
      enabled = notification.value.enabled
      threshold = notification.value.threshold
      threshold_type = notification.value.threshold_type  # Actual or Forecasted
      contact_emails = notification.value.contact_emails
      contact_roles = notification.value.contact_roles
      contact_groups = notification.value.contact_groups  # Action group IDs
    }
  }

  filter {
    tag {
      name    = var.filter_tag_name
      values  = var.filter_tag_values
    }
  }
}

# Optional: Action Group for budget alerts
resource "azurerm_monitor_action_group" "budget_alerts" {
  count               = var.create_action_group ? 1 : 0
  name                = "ag-budget-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "BudgetAlert"

  email_receiver {
    name          = "sendtoadmin"
    email_address = var.admin_email
  }
}
