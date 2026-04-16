# Shrink-VM Runbook
# Deallocates VM, resizes to smaller SKU, changes OS disk to HDD
# This script runs in Azure Automation with System Assigned Managed Identity

param(
    [Parameter(Mandatory=$false)]
    [string]$VmName,

    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup,

    [Parameter(Mandatory=$false)]
    [string]$TargetVmSize,

    [Parameter(Mandatory=$false)]
    [string]$TargetDiskSku
)

# Get values from Automation Variables if not provided
if (-not $VmName) { $VmName = Get-AutomationVariable -Name "VmName" }
if (-not $ResourceGroup) { $ResourceGroup = Get-AutomationVariable -Name "ResourceGroup" }
if (-not $TargetVmSize) { $TargetVmSize = Get-AutomationVariable -Name "TargetVmSize" }
if (-not $TargetDiskSku) { $TargetDiskSku = Get-AutomationVariable -Name "TargetDiskSku" }

Write-Output "Starting VM Shrink operation..."
Write-Output "VM: $VmName"
Write-Output "Resource Group: $ResourceGroup"
Write-Output "Target VM Size: $TargetVmSize"
Write-Output "Target Disk SKU: $TargetDiskSku"

# Connect to Azure using Managed Identity
Connect-AzAccount -Identity | Out-Null

# Step 1: Deallocate the VM
Write-Output "Step 1: Deallocating VM..."
Stop-AzVM -ResourceGroup $ResourceGroup -Name $VmName -Force
Write-Output "VM deallocated successfully"

# Step 2: Get the VM object
Write-Output "Step 2: Getting VM configuration..."
$vm = Get-AzVM -ResourceGroup $ResourceGroup -Name $VmName

# Step 3: Change VM size
Write-Output "Step 3: Changing VM size to $TargetVmSize..."
$vm.HardwareProfile.VmSize = $TargetVmSize
Update-AzVM -ResourceGroup $ResourceGroup -VM $vm
Write-Output "VM size updated successfully"

# Step 4: Change OS disk to target SKU (HDD)
Write-Output "Step 4: Changing OS disk SKU to $TargetDiskSku..."
$osDiskName = $vm.StorageProfile.OsDisk.Name
$disk = Get-AzDisk -ResourceGroupName $ResourceGroup -DiskName $osDiskName
$disk.Sku.Name = $TargetDiskSku
Update-AzDisk -ResourceGroupName $ResourceGroup -Disk $disk
Write-Output "OS disk SKU updated successfully"

Write-Output "========================================="
Write-Output "Shrink operation completed successfully!"
Write-Output "VM is now: $TargetVmSize with $TargetDiskSku disk"
Write-Output "VM remains deallocated. Start manually when needed."
Write-Output "========================================="
