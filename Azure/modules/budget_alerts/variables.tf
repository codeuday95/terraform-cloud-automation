variable "budget_name" {
  description = "Name identifier for the budget"
  type        = string
}

variable "resource_group_id" {
  description = "Resource Group ID for budget scope"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "budget_amount" {
  description = "Budget amount in currency"
  type        = number
}

variable "currency" {
  description = "Currency code (USD, CAD, etc.)"
  type        = string
  default     = "USD"
}

variable "time_grain" {
  description = "Budget period (Monthly, Quarterly, Annually)"
  type        = string
  default     = "Monthly"
}

variable "budget_start_date" {
  description = "Budget start date (YYYY-MM-DD)"
  type        = string
}

variable "budget_end_date" {
  description = "Budget end date (YYYY-MM-DD or null for ongoing)"
  type        = string
  default     = null
}

variable "notifications" {
  description = "List of notification configurations"
  type = list(object({
    enabled          = bool
    threshold        = number
    threshold_type   = string
    contact_emails   = list(string)
    contact_roles    = list(string)
    contact_groups   = list(string)
  }))
  default = [
    {
      enabled        = true
      threshold      = 50
      threshold_type = "Actual"
      contact_emails = []
      contact_roles  = []
      contact_groups = []
    },
    {
      enabled        = true
      threshold      = 80
      threshold_type = "Actual"
      contact_emails = []
      contact_roles  = []
      contact_groups = []
    },
    {
      enabled        = true
      threshold      = 100
      threshold_type = "Actual"
      contact_emails = []
      contact_roles  = []
      contact_groups = []
    }
  ]
}

variable "filter_tag_name" {
  description = "Tag name to filter budget (e.g., Workload)"
  type        = string
  default     = "Workload"
}

variable "filter_tag_values" {
  description = "Tag values to include in budget filter"
  type        = list(string)
  default     = []
}

variable "create_action_group" {
  description = "Create action group for alerts"
  type        = bool
  default     = false
}

variable "admin_email" {
  description = "Admin email for budget alerts"
  type        = string
  default     = ""
}
