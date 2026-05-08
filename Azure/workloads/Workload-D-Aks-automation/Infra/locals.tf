locals {
  # Common naming convention: <resource_type>-<workload>-<environment>-<location>
  base_name = "${var.workload_name}-${var.environment}-${var.location}"

  # ACR requires alphanumeric only, lowercase, 5-50 chars
  acr_name = replace("acr${var.workload_name}${var.environment}${var.location}", "-", "")

  # Key Vault requires alphanumeric and dashes only, 3-24 chars
  kv_name = substr(replace("kv-${var.workload_name}-${var.environment}-${var.location}", "/[^a-zA-Z0-9-]/", ""), 0, 24)

  rg_name   = "rg-${local.base_name}"
  vnet_name = "vnet-${local.base_name}"
  aks_name  = "aks-${local.base_name}"
}
