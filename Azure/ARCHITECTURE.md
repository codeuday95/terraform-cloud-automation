# Infrastructure Architecture

## Overview
This repository contains a Terraform-based infrastructure deployment for Azure, oriented around an enterprise-scale Hub and Spoke topology and a Landing Zone architecture.

### Directory Structure
- **`bootstrap/`**: Contains scripts to set up the initial Terraform state storage and platform resource groups in Azure.
- **`modules/`**: Contains reusable Terraform modules for creating and configuring Azure resources (AKS, App Gateway, Key Vault, VMs, Network, etc.).
- **`platform/`**: Manages the shared foundational infrastructure. This includes the Hub Virtual Network, Spoke Virtual Network, peering, central Log Analytics workspace, central Key Vault, as well as the initial Landing Zone constructs for the workloads. It separates environments via `dev`, `staging`, and `prod` configurations.
- **`workloads/`**: Contains the specific workload implementations (e.g., `workload-a`, `workload-b`) that are deployed into the Landing Zones provided by the platform layer. Environment configurations are also separated here.
- **`automation_scripts/`**: Contains utility scripts (e.g., PowerShell scripts) for operational tasks such as expanding or shrinking VMs.

## Azure Resource Hierarchy & Network Topology 
Based on the current codebase scope, the environment operates under a single Tenant, a single Management Group, and a single Subscription. Resources are isolated and secured at the Resource Group boundary.

Below is an ASCII diagram showing how the current deployment maps to this hierarchy, zooming into the Resource Groups and Virtual Networks:

```text
               [ Azure Active Directory (Entra ID) / Tenant ]
                                     |
                           [ Management Group ]
                                     |
                             [ Subscription ]
                                     |
       +-----------------------------+-----------------------------+
       |                                                           |
+------+-----------------------------+              +--------------+--------------+
|   Resource Group: Platform         |              | Resource Group: Workload-A  |
|                                    |              |                             |
|  [ Hub VNet (vnet-hub-<env>) ]     |              |  [ Subnet-workload-a ]      |
|   + Subnet1                        |  < Peered >  |   + AKS Cluster             |
|   + Subnet2                        |       |      |   + Identity                |
|                                    |       |      |   + Key Vault & Storage     |
|  - Log Analytics Workspace         |       |      +-----------------------------+
|  - Platform Key Vault              |       |                     |
|  - TF State Storage                |       |      +--------------+--------------+
|  - Platform SPN                    |       |      | Resource Group: Workload-B  |
+------------------------------------+       |      |                             |
                                             +----> |  [ Subnet-workload-b ]      |
                                                    |   +                         |
                                                    |   +                         |
                                                    |   +                         |
                                                    +-----------------------------+
```

*(Note: Workloads share a `Spoke VNet (vnet-spoke-<env>)` which lives in the Platform RG, but each workload is allocated dedicated Subnets within that Spoke VNet from which workload resources inside their respective App Resource Groups connect.)*

### Hierarchy & Network Breakdown:
1. **Directory (Tenant)**: The overarching identity boundary where your Azure Active Directory / Entra ID resides. All Service Principals (for platform and workloads) authenticate here.
2. **Management Group**: A single management group scope for applying baseline organizational policies.
3. **Subscription**: A single subscription housing all currently declared resources, acting as the primary billing boundary.
4. **Platform Resource Group (`rg-platform-<env>`)**: 
   - Deployed initially via bootstrap and platform Terraform.
   - **Networking**: Hosts both the **Hub VNet** (for shared infrastructure gateways and management) and the **Spoke VNet** (where workload subnets logically live).
   - **Shared Services**: Holds centralized logging (Log Analytics), core secrets (Platform Key Vault), state storage.
5. **Workload Resource Groups (`rg-workload-a-<env>`, `rg-workload-b-<env>`)**: 
   - Provisioned dynamically via the Landing Zone module.
   - **Networking**: Rely on specific Subnets delegated inside the shared Spoke VNet (e.g., `subnet-workload-a-<env>`). High security but shared peering. 
   - **Application Elements**: Contain workload isolated Storage Accounts, Key Vaults, Service Principals, and the actual runtimes like an AKS Cluster or App Gateway.

## Access Management & RBAC Policies
Identity and Access Management relies heavily on Service Principals (SPNs) managed dynamically by Azure Active Directory (Entra ID) and secured via Role-Based Access Control (RBAC). 

The RBAC implementation inside this project enforces least-privilege principles across platform operators and workload deployments:

### Entra ID Groups (Planned / Supported)
To scale human access beyond individual user assignments, the architecture supports creating and binding generic Azure AD Groups to specific Azure RBAC roles at either the Subscription or Resource Group scope:
- **`grp-platform-admins-<env>`**: Global administrators for the environment. Often mapped to `Owner` or `Contributor` + `User Access Administrator` on the Subscription.
- **`grp-workload-users-<env>`**: Standard users/developers responsible for managing workload application deployments. Typically mapped to `Contributor` on specific Workload RGs (`rg-workload-a-<env>`), allowing them to deploy code (e.g., to AKS) without allowing them to modify the underlying Spoke VNet or Platform Key Vault.
- **`grp-auditor-readers-<env>`**: Read-only auditors or monitoring staff. Typically mapped to `Reader` at the Subscription or Management Group level to view infrastructure state and billing without modification rights.

### Service Principal Assignments
1. **Platform Service Principal (`sp-platform-<env>`)**: 
   - Dynamically generated during platform provisioning.
   - Assigned the `Contributor` role scoped tightly to the **Platform Resource Group (`rg-platform-<env>`)**. This ensures platform automation can configure core networking, shared vaults, and monitoring resources, without having cross-tenant admin rights.
2. **Current User / Administrator Assignments**:
   - The user executing the Terraform context (`AzureAD Client Config Object ID`) is explicitly granted the `Key Vault Administrator` role over the Platform Key Vault to establish initial secrets.
3. **Workload Service Principals (`sp-<workload_name>-<env>`)**: 
   - Each workload (e.g., `workload-a`, `workload-b`) gets an individual Service Principal generated via `azuread_service_principal.workload` loops in the platform layer.
   - These are granted specific roles (such as `Contributor`) exclusively over their designated **Workload Resource Group (`rg-<workload>-<env>`)**.
   - **Network Joining**: They are also assigned `Network Contributor` permissions locally strictly over the specific Subnet (e.g., `subnet-workload-a-<env>`) inside the Spoke VNet in the Platform RG, so that they can bind compute components (like an AKS cluster or VM) to the network securely without modifying the broader Spoke VNet structure.
4. **Workload Landing Zone Restrictions**:
   - The user who triggers the provision retains `Key Vault Administrator` on the distinct Workload Key Vaults, and `Storage Blob Data Contributor` on the dedicated Workload Storage Accounts to ensure immediate setup permissions.

## Extensions & Integrations
The `modules/` folder showcases readiness for broader enterprise workloads incorporating:
- Compute (AKS, Linux VMs, Windows VMs)
- Networking & Security (Front Door, Network Security Groups, Bastion, Application Gateway)
- Operations (Azure Policy, Diagnostic Settings, Budget & Monitoring Alerts, Recovery Services Vault, Automation Accounts)
