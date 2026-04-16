variable "appgw_name" {
  description = "Name of the Application Gateway"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "create_resource_group" {
  description = "Create new resource group for App Gateway"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID for Application Gateway (must be dedicated subnet)"
  type        = string
}

variable "domain_name_label" {
  description = "DNS label for public IP (creates FQDN)"
  type        = string
  default     = null
}

# SKU Configuration
variable "sku_name" {
  description = "SKU name (Standard_v2 or WAF_v2)"
  type        = string
  default     = "WAF_v2"
}

variable "sku_tier" {
  description = "SKU tier (Standard_v2 or WAF_v2)"
  type        = string
  default     = "WAF_v2"
}

variable "capacity" {
  description = "Instance count (1-125)"
  type        = number
  default     = 2
}

# Backend Configuration
variable "backend_pool_name" {
  description = "Backend pool name"
  type        = string
  default     = "default-backend"
}

variable "backend_ip_addresses" {
  description = "List of backend IP addresses"
  type        = list(string)
  default     = []
}

variable "backend_fqdns" {
  description = "List of backend FQDNs"
  type        = list(string)
  default     = []
}

variable "backend_port" {
  description = "Backend port"
  type        = number
  default     = 80
}

# WAF Configuration
variable "enable_waf" {
  description = "Enable Web Application Firewall"
  type        = bool
  default     = true
}

variable "enable_waf_policy" {
  description = "Create separate WAF policy"
  type        = bool
  default     = true
}

variable "waf_mode" {
  description = "WAF mode (Prevention or Detection)"
  type        = string
  default     = "Prevention"
}

variable "waf_rule_set_type" {
  description = "WAF rule set type (OWASP)"
  type        = string
  default     = "OWASP"
}

variable "waf_rule_set_version" {
  description = "WAF rule set version"
  type        = string
  default     = "3.2"
}

variable "waf_file_upload_limit" {
  description = "File upload limit in MB"
  type        = number
  default     = 100
}

variable "waf_max_body_size" {
  description = "Max body size in KB"
  type        = number
  default     = 32
}

variable "waf_inspection_limit" {
  description = "Inspection limit in MiB"
  type        = number
  default     = 128
}

variable "waf_custom_rules" {
  description = "Custom WAF rules"
  type = list(object({
    name         = string
    priority     = number
    rule_type    = string
    action       = string
    match_variable = string
    operator     = string
    match_values = list(string)
  }))
  default = []
}

# Autoscale Configuration
variable "enable_autoscale" {
  description = "Enable autoscaling"
  type        = bool
  default     = true
}

variable "autoscale_min_capacity" {
  description = "Minimum instances"
  type        = number
  default     = 2
}

variable "autoscale_max_capacity" {
  description = "Maximum instances"
  type        = number
  default     = 10
}

# HTTPS Configuration
variable "enable_https" {
  description = "Enable HTTPS listener"
  type        = bool
  default     = false
}

variable "ssl_cert_name" {
  description = "SSL certificate name"
  type        = string
  default     = null
}

variable "host_names" {
  description = "Host names for HTTPS"
  type        = list(string)
  default     = []
}

# Probe Configuration
variable "enable_probe" {
  description = "Enable health probe"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
