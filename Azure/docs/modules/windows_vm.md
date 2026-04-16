# Windows VM Module

Windows VM module with NSG, boot diagnostics, and custom script extensions.

## Usage

```hcl
module "windows_vm" {
  source = "../../modules/windows_vm"

  vm_name               = "vm-windows-01"
  computer_name         = "WIN01"
  location              = "canadacentral"
  resource_group_name   = "rg-my-app"
  subnet_id             = "/subscriptions/.../subnet-id"
  
  vm_size               = "Standard_B2as_v2"
  admin_username        = "vmadmin"
  os_disk_size_gb       = 64
  os_disk_storage_type  = "StandardSSD_LRS"
  
  enable_public_ip      = true
  domain_name_label     = "my-vm"
  
  nsg_name              = "nsg-vm"
  nic_name              = "nic-vm"
  
  key_vault_id                    = "/subscriptions/.../keyvault"
  boot_diagnostics_storage_account_id = "/subscriptions/.../storage"
  boot_diagnostics_storage_account_name = "storageaccount"

  tags = {
    Environment = "dev"
    Purpose     = "Windows VM"
  }
}
```

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| `vm_name` | VM resource name | - |
| `computer_name` | Windows computer name | - |
| `location` | Azure region | - |
| `resource_group_name` | Resource group | - |
| `subnet_id` | Subnet for NIC | - |
| `vm_size` | VM SKU | `"Standard_B2as_v2"` |
| `admin_username` | Admin username | `"admin"` |
| `os_disk_size_gb` | OS disk size | `64` |
| `os_disk_storage_type` | Disk SKU | `"StandardSSD_LRS"` |
| `enable_public_ip` | Create public IP | `true` |
| `domain_name_label` | DNS label for public IP | `null` |
| `rdp_allowed_ips` | IPs allowed for RDP | `["VirtualNetwork"]` |

## Outputs

| Name | Description |
|------|-------------|
| `vm_id` | VM resource ID |
| `vm_name` | VM name |
| `private_ip_address` | Private IP |
| `public_ip_address` | Public IP (if enabled) |
| `nsg_id` | NSG resource ID |
| `admin_password_secret_name` | KeyVault secret name |

## Features

- [x] NSG with RDP rules
- [x] Boot diagnostics
- [x] Custom script extension (Chocolatey)
- [x] Admin credentials in Key Vault
- [x] Public IP (optional)
- [x] AzureRM v4.x compatible

## Installed Software (via Chocolatey)

- Google Chrome
- Notepad++
- TreeSize Free
- 7-Zip
- Firefox

## Notes

- Password auto-generated and stored in Key Vault
- NSG attached to NIC (AzureRM v4.x pattern)
- Uses Standard SKU Public IP (Static allocation)

