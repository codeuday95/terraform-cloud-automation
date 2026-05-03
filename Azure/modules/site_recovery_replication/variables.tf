variable "workload_name" {
  type = string
}
variable "primary_location" {
  type = string
}
variable "secondary_location" {
  type = string
}
variable "rg_primary_name" {
  type = string
}
variable "rg_secondary_name" {
  type = string
}
variable "rg_secondary_id" {
  type = string
}
variable "recovery_vault_name" {
  type = string
}
variable "vnet_primary_id" {
  type = string
}
variable "vnet_secondary_id" {
  type = string
}
variable "cache_storage_account_id" {
  type = string
}
variable "vm_id" {
  type = string
}
variable "vm_os_disk_id" {
  type = string
}
variable "vm_nic_id" {
  type = string
}
variable "target_subnet_name" {
  type    = string
  default = "snet-web"
}
