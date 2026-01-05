# ============================================================================
# Azure Infrastructure Cleanup Script (PowerShell)
#
# This script destroys all deployed infrastructure:
# - Backend layer (Application Gateway, Container Apps, ACR)
# - Base layer (VNet, Subnets, Key Vault, etc.)
#
# WARNING: This will DELETE all resources. Use with caution!
#
# Prerequisites:
# - Azure CLI installed and logged in
# - Terraform installed
#
# Usage:
#   .\destroy-infrastructure.ps1
#
# ============================================================================

$ErrorActionPreference = "Stop"

# Log file
$LogFile = "destroy-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Function to write colored output
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
    Add-Content -Path $LogFile -Value "[INFO] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
    Add-Content -Path $LogFile -Value "[SUCCESS] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
    Add-Content -Path $LogFile -Value "[WARNING] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    Add-Content -Path $LogFile -Value "[ERROR] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
}

function Write-Section {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Red
    Write-Host $Message -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Add-Content -Path $LogFile -Value "`n========================================"
    Add-Content -Path $LogFile -Value $Message
    Add-Content -Path $LogFile -Value "========================================"
}

# Function to destroy Terraform infrastructure
function Destroy-Terraform {
    param(
        [string]$LayerPath,
        [string]$LayerName
    )

    Write-Section "Destroying $LayerName"

    Push-Location $LayerPath
    Write-Info "Working directory: $(Get-Location)"

    try {
        # Initialize Terraform (in case it hasn't been initialized)
        Write-Info "Initializing Terraform..."
        terraform init -upgrade 2>&1 | Tee-Object -FilePath $LogFile -Append

        # Destroy
        Write-Info "Destroying Terraform resources..."
        terraform destroy -auto-approve 2>&1 | Tee-Object -FilePath $LogFile -Append
        Write-Success "$LayerName destroyed successfully!"

    } catch {
        Write-Error-Custom "Terraform destroy failed for $LayerName : $_"
        Pop-Location
        throw
    }

    Pop-Location
}

# Function to confirm destruction
function Confirm-Destruction {
    Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                   ⚠️  WARNING  ⚠️                       ║" -ForegroundColor Red
    Write-Host "║     This will DESTROY all deployed infrastructure!    ║" -ForegroundColor Red
    Write-Host "║                                                        ║" -ForegroundColor Red
    Write-Host "║  Resources to be deleted:                             ║" -ForegroundColor Red
    Write-Host "║  • Application Gateway                                 ║" -ForegroundColor Red
    Write-Host "║  • Container Apps & Environment                        ║" -ForegroundColor Red
    Write-Host "║  • Container Registry (ACR)                            ║" -ForegroundColor Red
    Write-Host "║  • Virtual Network & Subnets                           ║" -ForegroundColor Red
    Write-Host "║  • Key Vault (including SSL certificates)             ║" -ForegroundColor Red
    Write-Host "║  • Public IPs                                          ║" -ForegroundColor Red
    Write-Host "║  • Log Analytics & Application Insights                ║" -ForegroundColor Red
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""

    $confirmation = Read-Host "Type 'DELETE' to confirm destruction (case-sensitive)"

    if ($confirmation -ne "DELETE") {
        Write-Info "Destruction cancelled by user."
        exit 0
    }

    Write-Warning-Custom "Proceeding with infrastructure destruction..."
}

# Function to clean up orphaned resources
function Remove-OrphanedResources {
    Write-Section "Cleaning Up Orphaned Resources"

    # Check if resource groups exist and have resources
    $backendRg = "INFRA-PROD-BACKEND"
    $baseRg = "INFRA-PROD-BASE"

    try {
        # Check backend resource group
        $rgExists = az group exists --name $backendRg 2>$null
        if ($rgExists -eq "true") {
            Write-Info "Resource group $backendRg still exists. Checking for remaining resources..."

            # Get resource count
            $resourceCount = (az resource list --resource-group $backendRg --query "length(@)" -o tsv 2>$null)

            if ($resourceCount -gt 0) {
                Write-Warning-Custom "Found $resourceCount resources in $backendRg"
                $deleteRg = Read-Host "Delete resource group $backendRg entirely? (yes/no)"
                if ($deleteRg -eq "yes") {
                    Write-Info "Deleting resource group $backendRg..."
                    az group delete --name $backendRg --yes --no-wait 2>&1 | Tee-Object -FilePath $LogFile -Append
                    Write-Success "Resource group deletion initiated"
                }
            } else {
                Write-Info "No resources found in $backendRg"
            }
        }

        # Check base resource group
        $rgExists = az group exists --name $baseRg 2>$null
        if ($rgExists -eq "true") {
            Write-Info "Resource group $baseRg still exists. Checking for remaining resources..."

            $resourceCount = (az resource list --resource-group $baseRg --query "length(@)" -o tsv 2>$null)

            if ($resourceCount -gt 0) {
                Write-Warning-Custom "Found $resourceCount resources in $baseRg"
                $deleteRg = Read-Host "Delete resource group $baseRg entirely? (yes/no)"
                if ($deleteRg -eq "yes") {
                    Write-Info "Deleting resource group $baseRg..."
                    az group delete --name $baseRg --yes --no-wait 2>&1 | Tee-Object -FilePath $LogFile -Append
                    Write-Success "Resource group deletion initiated"
                }
            } else {
                Write-Info "No resources found in $baseRg"
            }
        }

    } catch {
        Write-Warning-Custom "Could not check for orphaned resources: $_"
    }
}

# ============================================================================
# MAIN DESTRUCTION FLOW
# ============================================================================

function Main {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║     Azure Infrastructure Cleanup Script               ║" -ForegroundColor Red
    Write-Host "║     ⚠️  DESTROY ALL RESOURCES  ⚠️                      ║" -ForegroundColor Red
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""

    # Confirm destruction
    Confirm-Destruction

    $startTime = Get-Date

    try {
        # Step 1: Destroy backend layer first (dependencies)
        Destroy-Terraform -LayerPath "azure-terrafrom\layers\400_backend\env\prod" -LayerName "Backend Layer (400_backend)"

        # Step 2: Destroy base layer
        Destroy-Terraform -LayerPath "azure-terrafrom\layers\100_base\env\prod" -LayerName "Base Layer (100_base)"

        # Step 3: Clean up any orphaned resources
        Remove-OrphanedResources

        # Calculate destruction time
        $endTime = Get-Date
        $duration = $endTime - $startTime
        $minutes = [math]::Floor($duration.TotalMinutes)
        $seconds = $duration.Seconds

        Write-Success "Total destruction time: ${minutes}m ${seconds}s"

        # Display summary
        Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║          INFRASTRUCTURE DESTROYED SUCCESSFULLY!        ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host "`n📝 Destruction log saved to: $LogFile" -ForegroundColor Cyan
        Write-Host ""

    } catch {
        Write-Error-Custom "Destruction failed! Check $LogFile for details."
        Write-Error-Custom $_.Exception.Message
        Write-Host "`nYou may need to manually delete resources in the Azure Portal." -ForegroundColor Yellow
        exit 1
    }
}

# Run main function
Main
