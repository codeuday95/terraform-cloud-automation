variable "policy_scope" {
  description = "Scope identifier for naming (e.g., workload-a, platform)"
  type        = string
}

variable "allowed_locations" {
  description = "List of allowed Azure locations"
  type        = list(string)
  default     = ["canadacentral", "canadaeast"]
}

variable "required_tags" {
  description = "List of required tags"
  type        = list(string)
  default     = ["Environment", "CostCenter", "Owner"]
}

variable "allowed_vm_skus" {
  description = "List of allowed VM SKUs"
  type        = list(string)
  default     = [
    "Standard_B1s",
    "Standard_B2s",
    "Standard_B2as_v2",
    "Standard_B2as_v2",
    "Standard_D2s_v3",
    "Standard_D4s_v3"
  ]
}

variable "assignment_scope" {
  description = "Scope where policy will be assigned (subscription, mg, or rg)"
  type        = string
}

variable "enforce" {
  description = "Enforce policy (true = deny, false = audit)"
  type        = bool
  default     = true
}
