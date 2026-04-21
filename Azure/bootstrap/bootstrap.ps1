#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory=$true)][string]$SubscriptionId,
    [Parameter(Mandatory=$true)][string]$TenantId,
    [Parameter(Mandatory=$true)][string]$OrganizationName,
    [Parameter(Mandatory=$false)][string]$Location = "",
    [Parameter(Mandatory=$false)][string]$DeveloperIP = ""
)

$ErrorActionPreference = "Stop"

# =============================================================================
# LOCATION SELECTION
# =============================================================================
$validLocations = @(
    "eastus",
    "eastus2",
    "westus",
    "westus2",
    "westeurope",
    "northeurope",
    "australiaeast",
    "canadacentral"
)

if (-not $Location -or $Location -notin $validLocations) {
    Write-Host ""
    Write-Host "Select an Azure region:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $validLocations.Count; $i++) {
        Write-Host "  [$($i+1)] $($validLocations[$i])"
    }
    do {
        $choice = Read-Host "Enter number (1-$($validLocations.Count))"
        $choiceInt = [int]$choice - 1
    } while ($choiceInt -lt 0 -or $choiceInt -ge $validLocations.Count)
    $Location = $validLocations[$choiceInt]
    Write-Host "Selected: $Location" -ForegroundColor Green
    Write-Host ""
}

# =============================================================================
# ENVIRONMENT SELECTION
# =============================================================================
$validEnvs = @("dev", "staging", "prod")
Write-Host ""
Write-Host "Select target environment:" -ForegroundColor Cyan
for ($i = 0; $i -lt $validEnvs.Count; $i++) {
    Write-Host "  [$($i+1)] $($validEnvs[$i])"
}
do {
    $choice = Read-Host "Enter number (1-$($validEnvs.Count))"
    $choiceInt = [int]$choice - 1
} while ($choiceInt -lt 0 -or $choiceInt -ge $validEnvs.Count)
$Env = $validEnvs[$choiceInt]
Write-Host "Selected: $Env" -ForegroundColor Green
Write-Host ""

# =============================================================================
# IP VALIDATION
# =============================================================================
if ($DeveloperIP) {
    if ($DeveloperIP -notmatch '^\d{1,3}(\.\d{1,3}){3}(/\d{1,2})?$') {
        Write-Error "DeveloperIP '$DeveloperIP' is not a valid IPv4 address or CIDR range. Example: 203.0.113.42 or 203.0.113.0/24"
        exit 1
    }
}

# =============================================================================
# NAME GENERATION (with length guards)
# =============================================================================
$orgPrefix = $OrganizationName.ToLower() -replace '[^a-z0-9]', ''
$regionPrefix = $Location.Substring(0, [Math]::Min(4, $Location.Length)).ToLower()
$instance = "001"

# Pattern: <resource-type>-<workload/app>-<environment>-<region>-<instance>

# Storage account: max 24 chars, alphanumeric only
$rawStorageName     = "stbootstrap${Env}${regionPrefix}${instance}"
$storageAccountName = ($rawStorageName -replace '[^a-z0-9]', '').Substring(0, [Math]::Min(24, $rawStorageName.Length))

# Key Vault: max 24 chars, alphanumeric + hyphens
$rawKvName    = "kv-boot-${Env}-${regionPrefix}-${instance}"
$keyVaultName = $rawKvName.Substring(0, [Math]::Min(24, $rawKvName.Length))

$resourceGroupName = "rg-bootstrap-${Env}-${Location}-${instance}"
$platformResourceGroupName = "rg-platform-${Env}-${Location}-${instance}"

$spName            = "sp-bootstrap-${Env}-${Location}-${instance}"
$adminGroupName    = "grp-bootstrap-${Env}-${Location}-${instance}"

$platformSpName    = "sp-platform-${Env}-${Location}-${instance}"
$platformGroupName = "grp-platform-${Env}-${Location}-${instance}"

# Platform Storage account (max 24)
$rawPlatSaName = "stplatform${Env}${regionPrefix}${instance}"
$platformStorageAccountName = ($rawPlatSaName -replace '[^a-z0-9]', '').Substring(0, [Math]::Min(24, $rawPlatSaName.Length))

# Platform Key Vault (max 24)
$rawPlatKvName = "kv-plat-${Env}-${regionPrefix}-${instance}"
$platformKeyVaultName = $rawPlatKvName.Substring(0, [Math]::Min(24, $rawPlatKvName.Length))

# =============================================================================
# PREFLIGHT SUMMARY
# =============================================================================
Write-Host ""
Write-Host "=== BOOTSTRAP STARTING ===" -ForegroundColor Cyan
Write-Host "Organization  : $OrganizationName"
Write-Host "Environment   : $Env"
Write-Host "Location      : $Location"
Write-Host "Bootstrap RG  : $resourceGroupName"
Write-Host "Platform RG   : $platformResourceGroupName"
Write-Host "Bootstrap SA  : $storageAccountName"
Write-Host "Platform SA   : $platformStorageAccountName"
Write-Host "Bootstrap KV  : $keyVaultName"
Write-Host "Platform KV   : $platformKeyVaultName"
Write-Host "Bootstrap SP  : $spName"
Write-Host "Admin Group   : $adminGroupName"
Write-Host "Platform SP   : $platformSpName"
Write-Host "Platform Group: $platformGroupName"
if ($DeveloperIP) {
    Write-Host "Developer IP  : $DeveloperIP (whitelisted on storage + KV)" -ForegroundColor DarkCyan
} else {
    Write-Host "Developer IP  : not set (storage + KV will be publicly accessible)" -ForegroundColor DarkYellow
}
Write-Host ""

# =============================================================================
# STEP 1: Validate Azure context
# =============================================================================
Write-Host "Step 1: Validating Azure context" -ForegroundColor Yellow
az account set --subscription $SubscriptionId
Write-Host "OK"

# =============================================================================
# STEP 2: Create RBAC admin group
# =============================================================================
Write-Host "Step 2: Creating RBAC admin group" -ForegroundColor Yellow
$existing = az ad group list --display-name $adminGroupName --query "[0].id" -o tsv 2>/dev/null
if ($existing) {
    Write-Host "Already exists: $existing"
    $adminGroupId = $existing
} else {
    $newGroup = az ad group create `
        --display-name $adminGroupName `
        --mail-nickname ($adminGroupName -replace '-', '') `
        --description "Root admin group for $OrganizationName — subscription Contributor + UAA + KV Administrator" | ConvertFrom-Json
    $adminGroupId = $newGroup.id
    Write-Host "Created: $adminGroupId"
}

# =============================================================================
# STEP 3: Create resource group
# =============================================================================
Write-Host "Step 3: Creating Bootstrap resource group" -ForegroundColor Yellow
$rgExists = az group exists --name $resourceGroupName
if ($rgExists -eq "true") {
    Write-Host "Bootstrap RG already exists"
} else {
    az group create --name $resourceGroupName --location $Location | Out-Null
    Write-Host "Bootstrap RG created"
}

Write-Host "Step 3.1: Creating Platform resource group" -ForegroundColor Yellow
$platformRgExists = az group exists --name $platformResourceGroupName
if ($platformRgExists -eq "true") {
    Write-Host "Platform RG already exists"
} else {
    az group create --name $platformResourceGroupName --location $Location | Out-Null
    Write-Host "Platform RG created"
}

# =============================================================================
# STEP 4: Create storage account
# =============================================================================
Write-Host "Step 4: Creating Bootstrap storage account" -ForegroundColor Yellow
$saExists = az storage account show --name $storageAccountName --resource-group $resourceGroupName 2>/dev/null
if ($saExists) {
    Write-Host "Already exists"
} else {
    $saCmd = @(
        "storage", "account", "create",
        "--name", $storageAccountName,
        "--resource-group", $resourceGroupName,
        "--location", $Location,
        "--sku", "Standard_LRS",
        "--kind", "StorageV2",
        "--https-only", "true",
        "--min-tls-version", "TLS1_2"
    )

    if ($DeveloperIP) {
        $saCmd += @("--default-action", "Deny", "--bypass", "AzureServices")
        Write-Host "  Firewall: restricting public access, whitelisting $DeveloperIP"
    }

    az @saCmd | Out-Null

    if ($DeveloperIP) {
        az storage account network-rule add `
            --account-name $storageAccountName `
            --resource-group $resourceGroupName `
            --ip-address $DeveloperIP | Out-Null
        Write-Host "  Network rule added for $DeveloperIP"
    }

    Write-Host "Bootstrap SA created"
}

Write-Host "Step 4.1: Creating Platform storage account" -ForegroundColor Yellow
$platformSaExists = az storage account show --name $platformStorageAccountName --resource-group $platformResourceGroupName 2>/dev/null
if ($platformSaExists) {
    Write-Host "Platform SA already exists"
} else {
    $platSaCmd = @(
        "storage", "account", "create",
        "--name", $platformStorageAccountName,
        "--resource-group", $platformResourceGroupName,
        "--location", $Location,
        "--sku", "Standard_LRS",
        "--kind", "StorageV2",
        "--https-only", "true",
        "--min-tls-version", "TLS1_2"
    )

    if ($DeveloperIP) {
        $platSaCmd += @("--default-action", "Deny", "--bypass", "AzureServices")
        Write-Host "  Firewall: restricting public access, whitelisting $DeveloperIP"
    }

    az @platSaCmd | Out-Null

    if ($DeveloperIP) {
        az storage account network-rule add `
            --account-name $platformStorageAccountName `
            --resource-group $platformResourceGroupName `
            --ip-address $DeveloperIP | Out-Null
        Write-Host "  Network rule added for $DeveloperIP"
    }

    Write-Host "Platform SA created"
}

# =============================================================================
# STEP 5: Create Key Vault (RBAC mode — required for role assignments to work)
# =============================================================================
Write-Host "Step 5: Creating Bootstrap Key Vault" -ForegroundColor Yellow
$kvExists = az keyvault show --name $keyVaultName --resource-group $resourceGroupName 2>/dev/null
if ($kvExists) {
    Write-Host "Already exists"
} else {
    $kvCmd = @(
        "keyvault", "create",
        "--name", $keyVaultName,
        "--resource-group", $resourceGroupName,
        "--location", $Location,
        "--enable-rbac-authorization", "true"
    )

    if ($DeveloperIP) {
        $kvCmd += @(
            "--default-action", "Deny",
            "--bypass", "AzureServices",
            "--network-acls-ips", $DeveloperIP
        )
        Write-Host "  Firewall: restricting public access, whitelisting $DeveloperIP"
    }

    az @kvCmd | Out-Null
    Write-Host "Bootstrap KV created"
}

Write-Host "Step 5.1: Creating Platform Key Vault" -ForegroundColor Yellow
$platKvExists = az keyvault show --name $platformKeyVaultName --resource-group $platformResourceGroupName 2>/dev/null
if ($platKvExists) {
    Write-Host "Platform KV already exists"
} else {
    $platKvCmd = @(
        "keyvault", "create",
        "--name", $platformKeyVaultName,
        "--resource-group", $platformResourceGroupName,
        "--location", $Location,
        "--enable-rbac-authorization", "true"
    )

    if ($DeveloperIP) {
        $platKvCmd += @(
            "--default-action", "Deny",
            "--bypass", "AzureServices",
            "--network-acls-ips", $DeveloperIP
        )
        Write-Host "  Firewall: restricting public access, whitelisting $DeveloperIP"
    }

    az @platKvCmd | Out-Null
    Write-Host "Platform KV created"
}

# =============================================================================
# STEP 6: Create storage containers
# =============================================================================
Write-Host "Step 6: Creating storage containers" -ForegroundColor Yellow

# Bootstrap Container
$bootContainerExists = az storage container exists --name "bootstrap" --account-name $storageAccountName --auth-mode login 2>/dev/null | ConvertFrom-Json
if ($bootContainerExists.exists) {
    Write-Host "  - bootstrap: already exists in Boot SA"
} else {
    az storage container create --name "bootstrap" --account-name $storageAccountName --auth-mode login 2>/dev/null | Out-Null
    Write-Host "  - bootstrap: created in Boot SA"
}

# Platform Containers
$platContainers = @("platform", "workloads")
foreach ($container in $platContainers) {
    $containerExists = az storage container exists `
        --name $container `
        --account-name $platformStorageAccountName `
        --auth-mode login 2>/dev/null | ConvertFrom-Json
    if ($containerExists.exists) {
        Write-Host "  - ${container}: already exists in Platform SA"
    } else {
        az storage container create `
            --name $container `
            --account-name $platformStorageAccountName `
            --auth-mode login 2>/dev/null | Out-Null
        Write-Host "  - ${container}: created in Platform SA"
    }
}

# =============================================================================
# STEP 7: Create service principal + generate credential
# =============================================================================
Write-Host "Step 7: Creating service principal" -ForegroundColor Yellow
$spExists    = az ad sp list --display-name $spName --query "[0].id" -o tsv 2>/dev/null
$spClientSecret = $null

if ($spExists) {
    Write-Host "SP already exists — rolling a new credential"
    $spObjectId = $spExists
    $spAppId    = az ad sp show --id $spObjectId --query appId -o tsv

    $credential     = az ad app credential reset `
        --id $spAppId `
        --display-name "bootstrap-secret" `
        --years 2 | ConvertFrom-Json
    $spClientSecret = $credential.password
    Write-Host "New credential issued for existing SP: $spObjectId"
} else {
    $app    = az ad app create --display-name $spName | ConvertFrom-Json
    $spAppId = $app.appId

    $sp         = az ad sp create --id $spAppId | ConvertFrom-Json
    $spObjectId = $sp.id

    $credential     = az ad app credential reset `
        --id $spAppId `
        --display-name "bootstrap-secret" `
        --years 2 | ConvertFrom-Json
    $spClientSecret = $credential.password

    Write-Host "Created SP: $spObjectId  AppId: $spAppId"
}

# =============================================================================
# STEP 8: Set current user as SP/app owner
# =============================================================================
Write-Host "Step 8: Adding current user as SP owner" -ForegroundColor Yellow
$currentUser = az ad signed-in-user show --query id -o tsv
az ad app owner add --id $spAppId --owner-object-id $currentUser 2>/dev/null | Out-Null
Write-Host "Current user set as app owner"

# =============================================================================
# STEP 9: Add members to admin group
# =============================================================================
Write-Host "Step 9: Adding members to admin group" -ForegroundColor Yellow
az ad group member add --group $adminGroupId --member-id $currentUser 2>/dev/null | Out-Null
az ad group member add --group $adminGroupId --member-id $spObjectId 2>/dev/null | Out-Null
Write-Host "Added: current user + service principal"

# =============================================================================
# STEP 10: Assign Key Vault Administrator (on the vault resource)
# =============================================================================
Write-Host "Step 10: Assigning Key Vault RBAC to Bootstrap" -ForegroundColor Yellow
$kvId = "/subscriptions/$SubscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.KeyVault/vaults/$keyVaultName"
az role assignment create `
    --role "Key Vault Administrator" `
    --assignee-object-id $adminGroupId `
    --scope $kvId `
    --assignee-principal-type Group 2>/dev/null | Out-Null
Write-Host "Key Vault Administrator assigned to $adminGroupName for Bootstrap KV"

Write-Host "Step 10.1: Assigning Key Vault RBAC to Platform" -ForegroundColor Yellow
$platKvId = "/subscriptions/$SubscriptionId/resourceGroups/$platformResourceGroupName/providers/Microsoft.KeyVault/vaults/$platformKeyVaultName"
az role assignment create `
    --role "Key Vault Administrator" `
    --assignee-object-id $adminGroupId `
    --scope $platKvId `
    --assignee-principal-type Group 2>/dev/null | Out-Null
# Giving platform group access to their own KV
az role assignment create `
    --role "Key Vault Administrator" `
    --assignee-object-id ($platformExisting ? $platformExisting : $platformGroupId) `
    --scope $platKvId `
    --assignee-principal-type Group 2>/dev/null | Out-Null
Write-Host "Key Vault Administrator assigned to Admins & Platform Group for Platform KV"

# =============================================================================
# STEP 11: Assign Contributor and UAA on subscription (formerly Owner)
# =============================================================================
Write-Host "Step 11: Assigning subscription roles to Admin Group" -ForegroundColor Yellow
$adminRoles = @("Contributor", "User Access Administrator")
foreach ($role in $adminRoles) {
    az role assignment create `
        --role $role `
        --assignee-object-id $adminGroupId `
        --scope "/subscriptions/$SubscriptionId" `
        --assignee-principal-type Group 2>/dev/null | Out-Null
    Write-Host "$role assigned on subscription to admin group"
}

# =============================================================================
# STEP 11.1: Create Platform RBAC Group
# =============================================================================
Write-Host "Step 11.1: Creating Platform RBAC Group" -ForegroundColor Yellow
$platformExisting = az ad group list --display-name $platformGroupName --query "[0].id" -o tsv 2>/dev/null
if ($platformExisting) {
    Write-Host "Already exists: $platformExisting"
    $platformGroupId = $platformExisting
} else {
    $platformNewGroup = az ad group create `
        --display-name $platformGroupName `
        --mail-nickname ($platformGroupName -replace '-', '') `
        --description "Platform admin group for $Env environment" | ConvertFrom-Json
    $platformGroupId = $platformNewGroup.id
    Write-Host "Created: $platformGroupId"
}

# =============================================================================
# STEP 11.2: Create Platform Service Principal
# =============================================================================
Write-Host "Step 11.2: Creating Platform Service Principal" -ForegroundColor Yellow
$platformSpExists = az ad sp list --display-name $platformSpName --query "[0].id" -o tsv 2>/dev/null
$platformSpClientSecret = $null

if ($platformSpExists) {
    Write-Host "Platform SP exists — rolling a new credential"
    $platformSpObjectId = $platformSpExists
    $platformSpAppId    = az ad sp show --id $platformSpObjectId --query appId -o tsv

    $credential = az ad app credential reset `
        --id $platformSpAppId `
        --display-name "platform-secret" `
        --years 2 | ConvertFrom-Json
    $platformSpClientSecret = $credential.password
    Write-Host "New credential issued: $platformSpObjectId"
} else {
    $app = az ad app create --display-name $platformSpName | ConvertFrom-Json
    $platformSpAppId = $app.appId

    $sp = az ad sp create --id $platformSpAppId | ConvertFrom-Json
    $platformSpObjectId = $sp.id

    $credential = az ad app credential reset `
        --id $platformSpAppId `
        --display-name "platform-secret" `
        --years 2 | ConvertFrom-Json
    $platformSpClientSecret = $credential.password

    Write-Host "Created Platform SP: $platformSpObjectId AppId: $platformSpAppId"
}
az ad app owner add --id $platformSpAppId --owner-object-id $currentUser 2>/dev/null | Out-Null

az ad group member add --group $platformGroupId --member-id $platformSpObjectId 2>/dev/null | Out-Null
Write-Host "Platform SP added to Platform group"

# =============================================================================
# STEP 11.3: Assign Contributor and UAA for Platform Group
# =============================================================================
Write-Host "Step 11.3: Assigning roles to Platform Group" -ForegroundColor Yellow
# Assigning at the subscription level to allow the Platform Group to create new Resource Groups for workloads
$subscriptionScope = "/subscriptions/$SubscriptionId"
foreach ($role in $adminRoles) {
    az role assignment create `
        --role $role `
        --assignee-object-id ($platformExisting ? $platformExisting : $platformGroupId) `
        --scope $subscriptionScope `
        --assignee-principal-type Group 2>/dev/null | Out-Null
    Write-Host "$role assigned to Platform group on Subscription context"
}

# =============================================================================
# STEP 11.4: Assign Azure AD and Subscription Policy Permissions to Platform
# =============================================================================
Write-Host "Step 11.4: Assigning global Policy and Azure AD permissions to Platform SP" -ForegroundColor Yellow

# 1. Resource Policy Contributor to Subscription
az role assignment create `
    --role "Resource Policy Contributor" `
    --assignee-object-id $platformGroupId `
    --scope "/subscriptions/$SubscriptionId" `
    --assignee-principal-type Group 2>/dev/null | Out-Null
Write-Host "Resource Policy Contributor assigned to Platform Group on Subscription level"

# 2. Graph API permissions for App & Group Creation
# Microsoft Graph API has AppID: 00000003-0000-0000-c000-000000000000
# 1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9 = Application.ReadWrite.All
# 62a82d76-70ea-41e2-9197-370581804d09 = Group.ReadWrite.All
az ad app permission add `
    --id $platformSpAppId `
    --api 00000003-0000-0000-c000-000000000000 `
    --api-permissions 1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9=Role 62a82d76-70ea-41e2-9197-370581804d09=Role 2>/dev/null | Out-Null

Write-Host "Waiting 10s for API permission propagation..."
Start-Sleep -Seconds 10
az ad app permission admin-consent --id $platformSpAppId 2>/dev/null | Out-Null
Write-Host "Admin consent granted for Graph API (App and Group creation)"

# =============================================================================
# STEP 12: Wait for RBAC propagation then store all secrets
# =============================================================================
Write-Host "Step 12: Storing secrets in Key Vaults" -ForegroundColor Yellow
Write-Host "Waiting 30s for RBAC propagation (Key Vault Administrator role)..."
Start-Sleep -Seconds 30

$bootSecrets = [ordered]@{
    "sp-bootstrap-client-id"             = $spAppId
    "sp-bootstrap-client-secret"         = $spClientSecret
    "sp-bootstrap-object-id"             = $spObjectId
    "azure-subscription-id"              = $SubscriptionId
    "azure-tenant-id"                    = $TenantId
    "storage-account-name"               = $storageAccountName
}

$platSecrets = [ordered]@{
    "sp-platform-${Env}-client-id"          = $platformSpAppId
    "sp-platform-${Env}-client-secret"      = $platformSpClientSecret
    "sp-platform-${Env}-object-id"          = $platformSpObjectId
    "azure-subscription-id"                 = $SubscriptionId
    "azure-tenant-id"                       = $TenantId
    "storage-account-name"                  = $platformStorageAccountName
}

# Store Bootstrap Secrets
foreach ($secretName in $bootSecrets.Keys) {
    $secretValue  = $bootSecrets[$secretName]
    $secretExists = az keyvault secret show --vault-name $keyVaultName --name $secretName 2>/dev/null
    if ($secretExists) {
        az keyvault secret set --vault-name $keyVaultName --name $secretName --value $secretValue | Out-Null
        Write-Host "  - [Bootstrap KV] ${secretName}: updated"
    } else {
        az keyvault secret set --vault-name $keyVaultName --name $secretName --value $secretValue | Out-Null
        Write-Host "  - [Bootstrap KV] ${secretName}: stored"
    }
}

# Store Platform Secrets
foreach ($secretName in $platSecrets.Keys) {
    $secretValue  = $platSecrets[$secretName]
    $secretExists = az keyvault secret show --vault-name $platformKeyVaultName --name $secretName 2>/dev/null
    if ($secretExists) {
        az keyvault secret set --vault-name $platformKeyVaultName --name $secretName --value $secretValue | Out-Null
        Write-Host "  - [Platform KV] ${secretName}: updated"
    } else {
        az keyvault secret set --vault-name $platformKeyVaultName --name $secretName --value $secretValue | Out-Null
        Write-Host "  - [Platform KV] ${secretName}: stored"
    }
}

# Clear SP secret from memory immediately after storing
$spClientSecret = $null
$platformSpClientSecret = $null
$bootSecrets["sp-${orgPrefix}-client-secret"] = $null
$platSecrets["sp-platform-${Env}-client-secret"] = $null

# =============================================================================
# SUMMARY DEPLOYMENT TABLE
# =============================================================================
Write-Host ""
Write-Host "=== BOOTSTRAP COMPLETE ===" -ForegroundColor Green
Write-Host ""

$summaryData = @(
    [PSCustomObject]@{ ResourceType = "Environment"; Name = $Env; Details = "Target deployment context" }
    [PSCustomObject]@{ ResourceType = "Bootstrap RG"; Name = $resourceGroupName; Details = "Hosts Admin state & secrets" }
    [PSCustomObject]@{ ResourceType = "Platform RG"; Name = $platformResourceGroupName; Details = "Hosts Platform state & secrets" }
    [PSCustomObject]@{ ResourceType = "Bootstrap SA"; Name = $storageAccountName; Details = "Container: bootstrap" }
    [PSCustomObject]@{ ResourceType = "Platform SA"; Name = $platformStorageAccountName; Details = "Containers: platform, workloads" }
    [PSCustomObject]@{ ResourceType = "Bootstrap KV"; Name = $keyVaultName; Details = "RBAC enabled, Bootstrap Secrets stored" }
    [PSCustomObject]@{ ResourceType = "Platform KV"; Name = $platformKeyVaultName; Details = "RBAC enabled, Platform Secrets stored" }
    [PSCustomObject]@{ ResourceType = "Bootstrap SP"; Name = $spName; Details = "Owner: Current user" }
    [PSCustomObject]@{ ResourceType = "Admin Group"; Name = $adminGroupName; Details = "Contributor + UAA + KV Admin" }
    [PSCustomObject]@{ ResourceType = "Platform SP"; Name = $platformSpName; Details = "Stored in: sp-platform-${Env}-*" }
    [PSCustomObject]@{ ResourceType = "Platform Group"; Name = $platformGroupName; Details = "Contributor + UAA (Scoped to Platform RG)" }
)

if ($DeveloperIP) {
    $summaryData += [PSCustomObject]@{ ResourceType = "Firewall Rule"; Name = $DeveloperIP; Details = "Whitelisted on Storage & Key Vault" }
}

$summaryData | Format-Table -Property ResourceType, Name, Details -AutoSize | Out-String | Write-Host

Write-Host "IMPORTANT: SP client secrets expire in 2 years. Rotate with:" -ForegroundColor DarkYellow
Write-Host "  az ad app credential reset --id $spAppId --display-name 'bootstrap-secret' --years 2"
Write-Host "  az ad app credential reset --id $platformSpAppId --display-name 'platform-secret' --years 2"
if ($DeveloperIP) {
    Write-Host ""
    Write-Host "NOTE: Storage + KV are IP-restricted. CI/CD runner IPs must also be whitelisted." -ForegroundColor DarkYellow
    Write-Host "  az storage account network-rule add --account-name $storageAccountName --resource-group $resourceGroupName --ip-address <RUNNER_IP>"
    Write-Host "  az keyvault network-rule add --name $keyVaultName --resource-group $resourceGroupName --ip-address <RUNNER_IP>"
}
Write-Host ""

# =============================================================================
# GENERATE CLEANUP SCRIPT (TEARDOWN)
# =============================================================================
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$cleanupScriptFile = "teardown-bootstrap-${Env}-${regionPrefix}-${timestamp}.ps1"

$cleanupScriptContent = @"
#!/usr/bin/env pwsh
# =============================================================================
# Cleanup script for bootstrap resources 
# Generated on: $(Get-Date)
# Environment:  $Env
# Location:     $Location
# =============================================================================

Write-Host "Deleting Service Principals (Apps)..." -ForegroundColor Yellow
az ad app delete --id $spAppId 2>/dev/null
az ad app delete --id $platformSpAppId 2>/dev/null

Write-Host "Deleting Azure AD Groups..." -ForegroundColor Yellow
az ad group delete --group $adminGroupId 2>/dev/null
az ad group delete --group $platformGroupId 2>/dev/null

Write-Host "Deleting Resource Groups (This will delete Storage Accounts and Key Vaults)..." -ForegroundColor Yellow
az group delete --name $resourceGroupName --yes --no-wait
az group delete --name $platformResourceGroupName --yes --no-wait

Write-Host "Purging Soft-Deleted Key Vaults..." -ForegroundColor Yellow
az keyvault purge --name $keyVaultName --location $Location 2>/dev/null
az keyvault purge --name $platformKeyVaultName --location $Location 2>/dev/null

Write-Host "Teardown commands initiated." -ForegroundColor Green
"@

$cleanupScriptContent | Out-File -FilePath "./$cleanupScriptFile" -Encoding utf8
Write-Host "A teardown cleanup script has been generated: ./$cleanupScriptFile" -ForegroundColor Cyan
Write-Host ""