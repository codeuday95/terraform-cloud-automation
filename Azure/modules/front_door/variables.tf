variable "frontdoor_name" {
  description = "Name of the Front Door"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region (Front Door is global)"
  type        = string
  default     = "global"
}

# Backend Configuration
variable "primary_backend_address" {
  description = "Primary backend address (IP or FQDN)"
  type        = string
}

variable "secondary_backends" {
  description = "List of secondary backends"
  type = list(object({
    name    = string
    address = string
  }))
  default = []
}

# Health Probe Configuration
variable "health_probe_interval" {
  description = "Health probe interval in seconds"
  type        = number
  default     = 30
}

variable "health_probe_path" {
  description = "Health probe path"
  type        = string
  default     = "/"
}

variable "health_probe_protocol" {
  description = "Health probe protocol (Http or Https)"
  type        = string
  default     = "Http"
}

variable "health_probe_method" {
  description = "Health probe request type (GET or HEAD)"
  type        = string
  default     = "GET"
}

# WAF Configuration
variable "enable_waf" {
  description = "Enable Web Application Firewall"
  type        = bool
  default     = true
}

variable "waf_mode" {
  description = "WAF mode (Prevention or Detection)"
  type        = string
  default     = "Prevention"
}

variable "waf_blocked_ips" {
  description = "List of IPs to block"
  type        = list(string)
  default     = []
}

# Session Affinity
variable "session_affinity_enabled" {
  description = "Enable session affinity"
  type        = bool
  default     = false
}

variable "session_affinity_ttl_seconds" {
  description = "Session affinity TTL in seconds"
  type        = number
  default     = 3600
}

# Custom Domain Configuration
variable "enable_custom_domain" {
  description = "Enable custom domain"
  type        = bool
  default     = false
}

variable "custom_domain_name" {
  description = "Custom domain name"
  type        = string
  default     = null
}

variable "custom_domain_hostname" {
  description = "Custom domain hostname"
  type        = string
  default     = null
}

variable "certificate_type" {
  description = "Certificate type (FrontDoor or Customer)"
  type        = string
  default     = "FrontDoor"
}

variable "certificate_secret_id" {
  description = "Certificate secret ID (for Customer certificates)"
  type        = string
  default     = null
}

variable "tls_protocol_type" {
  description = "TLS protocol type"
  type        = string
  default     = "ServerName"
}

variable "minimum_tls_version" {
  description = "Minimum TLS version (TLS12 or TLS13)"
  type        = string
  default     = "TLS12"
}

# Route Configuration
variable "route_patterns_to_match" {
  description = "Patterns to match for routing"
  type        = list(string)
  default     = ["/*"]
}

variable "route_protocols_enabled" {
  description = "Protocols enabled for route"
  type        = list(string)
  default     = ["Http", "Https"]
}

variable "route_cache_enabled" {
  description = "Enable caching for route"
  type        = bool
  default     = false
}

variable "route_forwarding_protocol" {
  description = "Forwarding protocol (Http, Https, or MatchRequest)"
  type        = string
  default     = "MatchRequest"
}

variable "origin_host_header" {
  description = "Origin host header (optional, defaults to backend address if null)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
