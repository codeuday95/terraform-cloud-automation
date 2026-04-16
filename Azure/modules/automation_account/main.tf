# Azure Automation Account
# Note: For Free Trial subscriptions, must be in: eastus, eastus2, westus, northeurope, southeastasia, japanwest
resource "azurerm_automation_account" "main" {
  name                = var.automation_account_name
  location            = var.automation_location != null ? var.automation_location : var.location
  resource_group_name = var.resource_group_name

  sku_name = var.sku_name

  # Managed identity for runbook authentication
  identity {
    type = "SystemAssigned"
  }
}

# Variable for VM Name
resource "azurerm_automation_variable_string" "vm_name" {
  name                    = "VmName"
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.main.name
  value                   = var.vm_name
}

# Variable for Resource Group
resource "azurerm_automation_variable_string" "resource_group" {
  name                    = "ResourceGroup"
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.main.name
  value                   = var.resource_group_name
}

# Variable for Original VM Size
resource "azurerm_automation_variable_string" "original_vm_size" {
  name                    = "OriginalVmSize"
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.main.name
  value                   = var.original_vm_size
}

# Variable for Original Disk SKU
resource "azurerm_automation_variable_string" "original_disk_sku" {
  name                    = "OriginalDiskSku"
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.main.name
  value                   = var.original_disk_sku
}

# Variable for Target VM Size
resource "azurerm_automation_variable_string" "target_vm_size" {
  name                    = "TargetVmSize"
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.main.name
  value                   = var.target_vm_size
}

# Variable for Target Disk SKU
resource "azurerm_automation_variable_string" "target_disk_sku" {
  name                    = "TargetDiskSku"
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.main.name
  value                   = var.target_disk_sku
}

# RBAC: Grant Automation Account access to manage VMs
resource "azurerm_role_assignment" "automation_vm_contributor" {
  scope                = var.vm_resource_id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_automation_account.main.identity[0].principal_id
}

# RBAC: Grant Automation Account access to manage disks
resource "azurerm_role_assignment" "automation_disk_contributor" {
  scope                = var.vm_resource_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_automation_account.main.identity[0].principal_id
}

# Create Shrink-VM runbook using Azure CLI
resource "null_resource" "shrink_vm_runbook" {
  triggers = {
    script_hash = sha256(file("${path.module}/../../automation_scripts/shrink_vm.ps1"))
  }

  provisioner "local-exec" {
    command = <<-EOT
echo "Creating Shrink-VM runbook..."
az automation runbook create \
  --resource-group "${var.resource_group_name}" \
  --automation-account-name "${azurerm_automation_account.main.name}" \
  --name "Shrink-VM" \
  --type "PowerShell" \
  --description "Deallocates VM, resizes to B2ats_v2, changes disk to HDD" \
  --log-verbose --log-progress \
  --path "${path.module}/../../automation_scripts/shrink_vm.ps1" || true

echo "Publishing Shrink-VM runbook..."
az automation runbook publish \
  --resource-group "${var.resource_group_name}" \
  --automation-account-name "${azurerm_automation_account.main.name}" \
  --name "Shrink-VM" || true
EOT
  }

  depends_on = [
    azurerm_automation_account.main,
    azurerm_role_assignment.automation_vm_contributor,
    azurerm_role_assignment.automation_disk_contributor
  ]
}

# Create Expand-VM runbook using Azure CLI
resource "null_resource" "expand_vm_runbook" {
  triggers = {
    script_hash = sha256(file("${path.module}/../../automation_scripts/expand_vm.ps1"))
  }

  provisioner "local-exec" {
    command = <<-EOT
echo "Creating Expand-VM runbook..."
az automation runbook create \
  --resource-group "${var.resource_group_name}" \
  --automation-account-name "${azurerm_automation_account.main.name}" \
  --name "Expand-VM" \
  --type "PowerShell" \
  --description "Resizes VM to original, changes disk to SSD, starts VM" \
  --log-verbose --log-progress \
  --path "${path.module}/../../automation_scripts/expand_vm.ps1" || true

echo "Publishing Expand-VM runbook..."
az automation runbook publish \
  --resource-group "${var.resource_group_name}" \
  --automation-account-name "${azurerm_automation_account.main.name}" \
  --name "Expand-VM" || true
EOT
  }

  depends_on = [null_resource.shrink_vm_runbook]
}
