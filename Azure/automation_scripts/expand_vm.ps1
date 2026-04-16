# Expand-VM Runbook
# Resizes VM back to original SKU, changes OS disk to original SKU, and starts the VM
# This script runs in Azure Automation with System Assigned Managed Identity

param(
    [Parameter(Mandatory=$false)]
    [string]$VmName,

    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup,

    [Parameter(Mandatory=$false)]
    [string]$OriginalVmSize,

    [Parameter(Mandatory=$false)]
    [string]$OriginalDiskSku
)

# Get values from Automation Variables if not provided
if (-not $VmName) { $VmName = Get-AutomationVariable -Name "VmName" }
if (-not $ResourceGroup) { $ResourceGroup = Get-AutomationVariable -Name "ResourceGroup" }
if (-not $OriginalVmSize) { $OriginalVmSize = Get-AutomationVariable -Name "OriginalVmSize" }
if (-not $OriginalDiskSku) { $OriginalDiskSku = Get-AutomationVariable -Name "OriginalDiskSku" }

Write-Output "Starting VM Expand operation..."
Write-Output "VM: $VmName"
Write-Output "Resource Group: $ResourceGroup"
Write-Output "Original VM Size: $OriginalVmSize"
Write-Output "Original Disk SKU: $OriginalDiskSku"

# Connect to Azure using Managed Identity
Connect-AzAccount -Identity | Out-Null

# Step 1: Get the VM object
Write-Output "Step 1: Getting VM configuration..."
$vm = Get-AzVM -ResourceGroup $ResourceGroup -Name $VmName

# Step 2: Change VM size back to original
Write-Output "Step 2: Changing VM size to $OriginalVmSize..."
$vm.HardwareProfile.VmSize = $OriginalVmSize
Update-AzVM -ResourceGroup $ResourceGroup -VM $vm
Write-Output "VM size updated successfully"

# Step 3: Change OS disk back to original SKU (SSD)
Write-Output "Step 3: Changing OS disk SKU to $OriginalDiskSku..."
$osDiskName = $vm.StorageProfile.OsDisk.Name
$disk = Get-AzDisk -ResourceGroupName $ResourceGroup -DiskName $osDiskName
$disk.Sku.Name = $OriginalDiskSku
Update-AzDisk -ResourceGroupName $ResourceGroup -Disk $disk
Write-Output "OS disk SKU updated successfully"

# Step 4: Start the VM
Write-Output "Step 4: Starting VM..."
Start-AzVM -ResourceGroup $ResourceGroup -Name $VmName
Write-Output "VM started successfully"

Write-Output "========================================="
Write-Output "Expand operation completed successfully!"
Write-Output "VM is now: $OriginalVmSize with $OriginalDiskSku disk"
Write-Output "VM is running and ready to use."
Write-Output "========================================="
