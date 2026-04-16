variable "name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the resource group"
  type        = map(string)
  default     = {}
}

variable "lock_resource_group" {
  description = "Whether to apply a management lock to the resource group"
  type        = bool
  default     = false
}
