variable "dns_zone_name" {
  description = "DNS Zone name (e.g., workload-a.internal)"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "record_name" {
  description = "DNS record name (e.g., vm-win-workload-a)"
  type        = string
  default     = "@"
}

variable "vm_public_ip" {
  description = "VM Public IP address"
  type        = string
}

variable "ttl" {
  description = "DNS record TTL in seconds"
  type        = number
  default     = 300
}
