variable "server_name" {
  type = string
}
variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}
variable "admin_username" {
  type = string
}
variable "admin_password" {
  type = string
}
variable "create_database" {
  type    = bool
  default = true
}
variable "database_name" {
  type    = string
  default = "defaultdb"
}
variable "sku_name" {
  type    = string
  default = "S0"
}
variable "tags" {
  type    = map(string)
  default = {}
}
