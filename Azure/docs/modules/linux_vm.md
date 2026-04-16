# Linux VM Module

Linux VM module (Ubuntu 22.04) with NSG attachment and boot diagnostics.

## Usage

```hcl
module "linux_vm" {
  source = "../../modules/linux_vm"

  vm_name               = "vm-linux-01"
  location              = "canadacentral"
  resource_group_name   = "rg-my-app"
  subnet_id             = "/subscriptions/.../subnet-id"
  
  vm_size               = "Standard_B2as_v2"  # 2 vCPU, 4GB RAM
  admin_username        = "azureuser"
  admin_ssh_public_key  = "ssh-rsa AAAA..."
  
  os_disk_storage_account_type = "StandardSSD_LRS"
  enable_public_ip      = false
  nsg_id                = "/subscriptions/.../nsg-id"
  
  enable_boot_diagnostics = true
  boot_diagnostics_storage_account_uri = "https://storage.blob.core.windows.net/"

  tags = {
    Environment = "dev"
    Purpose     = "Linux VM"
  }
}
```

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| `vm_name` | VM resource name | - |
| `location` | Azure region | - |
| `resource_group_name` | Resource group | - |
| `subnet_id` | Subnet for NIC | - |
| `vm_size` | VM SKU | `"Standard_B2as_v2"` |
| `admin_username` | SSH username | `"azureuser"` |
| `admin_ssh_public_key` | SSH public key | `""` |
| `os_disk_storage_account_type` | Disk SKU | `"StandardSSD_LRS"` |
| `enable_public_ip` | Create public IP | `false` |
| `nsg_id` | NSG to attach | `null` |
| `enable_boot_diagnostics` | Enable diagnostics | `true` |

## Outputs

| Name | Description |
|------|-------------|
| `vm_id` | VM resource ID |
| `vm_name` | VM name |
| `private_ip` | Private IP address |
| `public_ip` | Public IP (if enabled) |
| `nic_id` | Network Interface ID |

## Features

- [x] Ubuntu 22.04 LTS
- [x] SSH key authentication
- [x] NSG attachment (AzureRM v4.x)
- [x] Boot diagnostics
- [x] Optional public IP
- [x] Zone resilient (configurable)

## Default Configuration

- **OS**: Ubuntu Server 22.04 LTS
- **Size**: Standard_B2as_v2 (2 vCPU, 4GB RAM)
- **Disk**: Standard SSD
- **Auth**: SSH key (password disabled)

## Notes

- SSH public key required for authentication
- NSG attached via separate association resource (AzureRM v4.x)
- Boot diagnostics uses platform storage account
