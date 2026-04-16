# Azure Automation Runbooks for VM Management

This folder contains PowerShell scripts for Azure Automation runbooks to manage VM size and disk SKU.

## Scripts

### shrink_vm.ps1
Deallocates the VM, resizes to a smaller VM size, and changes the OS disk to HDD (Standard_LRS).

### expand_vm.ps1
Resizes the VM back to the original size, changes the OS disk back to SSD, and starts the VM.

## How to Create Runbooks

1. Go to Azure Portal → Automation Account → Runbooks
2. Click "Create a runbook"
3. Select "PowerShell" as the runbook type
4. Copy the content from `shrink_vm.ps1` or `expand_vm.ps1`
5. Click "Save" and then "Publish"

## Variables

The following Automation Variables are created by Terraform:
- `VmName` - Name of the VM
- `ResourceGroup` - Resource group containing the VM
- `OriginalVmSize` - Original VM size (e.g., Standard_B2as_v2)
- `OriginalDiskSku` - Original disk SKU (e.g., StandardSSD_LRS)
- `TargetVmSize` - Target VM size for shrink (e.g., Standard_B2ats_v2)
- `TargetDiskSku` - Target disk SKU for shrink (e.g., Standard_LRS)

## Required Modules

The Automation Account needs the following Az modules installed:
- Az.Accounts
- Az.Compute
- Az.Resources

## How to Use

1. In the Azure Portal, go to your Automation Account
2. Click on "Runbooks"
3. Select "Shrink-VM" or "Expand-VM"
4. Click "Start" to execute the runbook
5. Monitor the job output for progress

## Notes

- The VM will be deallocated during the shrink operation
- You will not be charged for compute while the VM is deallocated
- Disk charges still apply based on the disk type
- The runbooks use the System Assigned Managed Identity for authentication
