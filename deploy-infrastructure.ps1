# ============================================================================
# Azure Infrastructure Deployment Script (PowerShell)
#
# This script automates the complete deployment of:
# - Base layer (VNet, Subnets, Key Vault, Application Gateway resources)
# - SSL Certificate generation and upload
# - Sample API Docker image build and push to ACR
# - Backend layer (Container Registry, Container App, Application Gateway)
#
# Prerequisites:
# - Azure CLI installed and logged in
# - Terraform installed (v1.0+)
# - Docker Desktop installed (for building sample API)
# - OpenSSL installed (Git Bash includes it)
# - Proper Azure subscription access
#
# Usage:
#   .\deploy-infrastructure.ps1
#
# ============================================================================

# Set error action preference
$ErrorActionPreference = "Stop"

# Log file
$LogFile = "deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Function to write colored output and log
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
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host $Message -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Add-Content -Path $LogFile -Value "`n========================================"
    Add-Content -Path $LogFile -Value $Message
    Add-Content -Path $LogFile -Value "========================================"
}

# Function to check if command exists
function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-Section "Checking Prerequisites"

    $allOk = $true

    # Check Azure CLI
    if (Test-CommandExists "az") {
        $azVersion = (az version --query '"azure-cli"' -o tsv)
        Write-Success "Azure CLI installed: $azVersion"
    } else {
        Write-Error-Custom "Azure CLI not found. Please install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        $allOk = $false
    }

    # Check Terraform
    if (Test-CommandExists "terraform") {
        $tfVersion = (terraform version -json | ConvertFrom-Json).terraform_version
        Write-Success "Terraform installed: $tfVersion"
    } else {
        Write-Error-Custom "Terraform not found. Please install from: https://www.terraform.io/downloads"
        $allOk = $false
    }

    # Check Docker
    if (Test-CommandExists "docker") {
        $dockerVersion = (docker --version).Split(' ')[2].TrimEnd(',')
        Write-Success "Docker installed: $dockerVersion"
    } else {
        Write-Warning-Custom "Docker not found. Sample API deployment will be skipped."
    }

    # Check OpenSSL
    if (Test-CommandExists "openssl") {
        $opensslVersion = (openssl version).Split(' ')[1]
        Write-Success "OpenSSL installed: $opensslVersion"
    } else {
        Write-Warning-Custom "OpenSSL not found. SSL certificate generation will be skipped."
    }

    # Check Azure login
    try {
        $account = az account show --query name -o tsv 2>$null
        $subscriptionId = az account show --query id -o tsv 2>$null
        Write-Success "Logged into Azure subscription: $account ($subscriptionId)"
    } catch {
        Write-Error-Custom "Not logged into Azure. Run: az login"
        $allOk = $false
    }

    if (-not $allOk) {
        Write-Error-Custom "Prerequisites check failed. Please fix the issues above."
        exit 1
    }

    Write-Success "All prerequisites satisfied!"
}

# Function to deploy Terraform
function Deploy-Terraform {
    param(
        [string]$LayerPath,
        [string]$LayerName
    )

    Write-Section "Deploying $LayerName"

    Push-Location $LayerPath
    Write-Info "Working directory: $(Get-Location)"

    try {
        # Initialize Terraform
        Write-Info "Initializing Terraform..."
        terraform init -upgrade 2>&1 | Tee-Object -FilePath $LogFile -Append
        Write-Success "Terraform initialized"

        # Plan
        Write-Info "Creating Terraform plan..."
        terraform plan -out=tfplan 2>&1 | Tee-Object -FilePath $LogFile -Append
        Write-Success "Terraform plan created"

        # Apply
        Write-Info "Applying Terraform changes..."
        terraform apply -auto-approve tfplan 2>&1 | Tee-Object -FilePath $LogFile -Append
        Write-Success "$LayerName deployed successfully!"

        # Clean up plan file
        Remove-Item -Path tfplan -ErrorAction SilentlyContinue

    } catch {
        Write-Error-Custom "Terraform deployment failed for $LayerName : $_"
        Pop-Location
        exit 1
    }

    Pop-Location
}

# Function to setup SSL certificate
function Setup-SSLCertificate {
    Write-Section "Setting Up SSL Certificate"

    if (-not (Test-CommandExists "openssl")) {
        Write-Warning-Custom "OpenSSL not found. Skipping SSL certificate generation."
        return
    }

    # Get Key Vault name
    Write-Info "Retrieving Key Vault name..."
    Push-Location "azure-terrafrom\layers\100_base\env\prod"
    try {
        $keyVaultName = terraform output -raw key_vault_name 2>$null
    } catch {
        Write-Error-Custom "Could not retrieve Key Vault name. Make sure base layer is deployed."
        Pop-Location
        exit 1
    }
    Pop-Location

    if ([string]::IsNullOrEmpty($keyVaultName)) {
        Write-Error-Custom "Could not retrieve Key Vault name. Make sure base layer is deployed."
        exit 1
    }

    Write-Info "Key Vault: $keyVaultName"

    # Check if certificate already exists
    $certExists = az keyvault certificate show --vault-name $keyVaultName --name ssl-certificate 2>$null
    if ($certExists) {
        Write-Warning-Custom "SSL certificate already exists in Key Vault. Skipping generation."
        return
    }

    # Generate self-signed certificate
    Write-Info "Generating self-signed SSL certificate..."
    $certDir = ".\temp-certs"
    New-Item -ItemType Directory -Path $certDir -Force | Out-Null

    # Create OpenSSL config file
    $opensslConfig = @"
[req]
distinguished_name=req
[san]
subjectAltName=DNS:ztf-appgateway.example.com,DNS:*.ztf-appgateway.example.com
"@
    $configFile = "$certDir\openssl.cnf"
    Set-Content -Path $configFile -Value $opensslConfig

    # Generate certificate
    openssl req -x509 -newkey rsa:4096 -sha256 -days 365 `
        -nodes -keyout "$certDir\ssl-certificate.key" `
        -out "$certDir\ssl-certificate.crt" `
        -subj "/CN=ztf-appgateway.example.com/O=INFRA/C=US" `
        -extensions san `
        -config $configFile 2>&1 | Tee-Object -FilePath $LogFile -Append

    # Convert to PFX format
    Write-Info "Converting certificate to PFX format..."
    openssl pkcs12 -export `
        -out "$certDir\ssl-certificate.pfx" `
        -inkey "$certDir\ssl-certificate.key" `
        -in "$certDir\ssl-certificate.crt" `
        -password pass: 2>&1 | Tee-Object -FilePath $LogFile -Append

    # Upload to Key Vault
    Write-Info "Uploading certificate to Key Vault..."
    try {
        az keyvault certificate import `
            --vault-name $keyVaultName `
            --name ssl-certificate `
            --file "$certDir\ssl-certificate.pfx" `
            --password "" 2>&1 | Tee-Object -FilePath $LogFile -Append
        Write-Success "SSL certificate uploaded to Key Vault"
    } catch {
        Write-Error-Custom "Failed to upload certificate to Key Vault: $_"
        exit 1
    }

    # Clean up temporary files
    Remove-Item -Path $certDir -Recurse -Force
    Write-Info "Cleaned up temporary certificate files"
}

# Function to deploy sample API
function Deploy-SampleAPI {
    Write-Section "Building and Deploying Sample API"

    if (-not (Test-CommandExists "docker")) {
        Write-Warning-Custom "Docker not found. Skipping sample API deployment."
        return
    }

    # Get ACR details
    Write-Info "Retrieving ACR details..."
    Push-Location "azure-terrafrom\layers\400_backend\env\prod"
    try {
        $acrServer = terraform output -raw acr_login_server 2>$null
        $acrName = $acrServer.Split('.')[0]
    } catch {
        Write-Error-Custom "Could not retrieve ACR name. Make sure backend layer is deployed."
        Pop-Location
        exit 1
    }
    Pop-Location

    if ([string]::IsNullOrEmpty($acrName)) {
        Write-Error-Custom "Could not retrieve ACR name. Make sure backend layer is deployed."
        exit 1
    }

    Write-Info "ACR Name: $acrName"

    # Login to ACR
    Write-Info "Logging into ACR..."
    az acr login --name $acrName 2>&1 | Tee-Object -FilePath $LogFile -Append
    Write-Success "Logged into ACR"

    # Build and push using ACR Build
    Write-Info "Building and pushing sample-api image to ACR..."
    Push-Location "azure-terrafrom\layers\400_backend\sample-api"

    try {
        az acr build --registry $acrName --image sample-api:latest . 2>&1 | Tee-Object -FilePath $LogFile -Append
        Write-Success "Sample API image built and pushed successfully!"
    } catch {
        Write-Error-Custom "Failed to build/push sample API image: $_"
        Pop-Location
        exit 1
    }

    Pop-Location

    # Restart Container App
    Write-Info "Restarting Container App to use new image..."
    Push-Location "azure-terrafrom\layers\400_backend\env\prod"
    $containerAppName = terraform output -raw container_app_name 2>$null
    Pop-Location
    $rgName = "INFRA-PROD-BACKEND"

    try {
        az containerapp revision restart `
            --name $containerAppName `
            --resource-group $rgName 2>&1 | Tee-Object -FilePath $LogFile -Append
        Write-Success "Container App restarted"
    } catch {
        Write-Warning-Custom "Could not restart Container App automatically. It will restart on its own."
    }
}

# Function to verify deployment
function Test-Deployment {
    Write-Section "Verifying Deployment"

    # Get Application Gateway public IP
    Write-Info "Retrieving Application Gateway public IP..."
    Push-Location "azure-terrafrom\layers\400_backend\env\prod"
    try {
        $appGwIp = terraform output -raw application_gateway_public_ip 2>$null
    } catch {
        Write-Warning-Custom "Could not retrieve Application Gateway IP. Skipping verification."
        Pop-Location
        return
    }
    Pop-Location

    if ([string]::IsNullOrEmpty($appGwIp)) {
        Write-Warning-Custom "Could not retrieve Application Gateway IP. Skipping verification."
        return
    }

    Write-Info "Application Gateway IP: $appGwIp"

    # Wait for Application Gateway to be ready
    Write-Info "Waiting 60 seconds for Application Gateway to stabilize..."
    Start-Sleep -Seconds 60

    # Test endpoints
    Write-Info "Testing API endpoints..."

    # Test root endpoint
    Write-Info "Testing root endpoint (/)..."
    try {
        $response = Invoke-WebRequest -Uri "https://$appGwIp/" -SkipCertificateCheck -TimeoutSec 30 -UseBasicParsing
        if ($response.Content -like "*Welcome*") {
            Write-Success "Root endpoint responding"
        }
    } catch {
        Write-Warning-Custom "Root endpoint not responding yet (may need more time to initialize)"
    }

    # Test health endpoint
    Write-Info "Testing health endpoint (/api/health)..."
    try {
        $response = Invoke-WebRequest -Uri "https://$appGwIp/api/health" -SkipCertificateCheck -TimeoutSec 30 -UseBasicParsing
        if ($response.Content -like "*healthy*") {
            Write-Success "Health endpoint responding"
        }
    } catch {
        Write-Warning-Custom "Health endpoint not responding yet (may need more time to initialize)"
    }

    # Check backend health
    Write-Info "Checking Application Gateway backend health..."
    $appGwName = "INFRA-apg-appgateway-prod-eus-001"
    $rgName = "INFRA-PROD-BACKEND"

    try {
        $healthStatus = az network application-gateway show-backend-health `
            --name $appGwName `
            --resource-group $rgName `
            --query "backendAddressPools[0].backendHttpSettingsCollection[0].servers[0].health" `
            -o tsv 2>$null

        if ($healthStatus -eq "Healthy") {
            Write-Success "Backend health status: Healthy"
        } else {
            Write-Warning-Custom "Backend health status: $healthStatus (may need more time to stabilize)"
        }
    } catch {
        Write-Warning-Custom "Could not check backend health status"
    }
}

# Function to display summary
function Show-Summary {
    Write-Section "Deployment Summary"

    # Get outputs
    Push-Location "azure-terrafrom\layers\400_backend\env\prod"
    $appGwIp = terraform output -raw application_gateway_public_ip 2>$null
    $containerAppFqdn = terraform output -raw container_app_fqdn 2>$null
    $acrServer = terraform output -raw acr_login_server 2>$null
    Pop-Location

    Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║          DEPLOYMENT COMPLETED SUCCESSFULLY!           ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host "`n📊 Infrastructure Details:" -ForegroundColor Cyan
    Write-Host "  • Application Gateway IP: $appGwIp" -ForegroundColor White
    Write-Host "  • Container App FQDN: $containerAppFqdn" -ForegroundColor White
    Write-Host "  • ACR Server: $acrServer" -ForegroundColor White
    Write-Host "`n🧪 Test Commands:" -ForegroundColor Cyan
    Write-Host "  curl -kL https://$appGwIp/" -ForegroundColor White
    Write-Host "  curl -kL https://$appGwIp/api/health" -ForegroundColor White
    Write-Host "  curl -kL https://$appGwIp/api/test" -ForegroundColor White
    Write-Host "`n📚 Documentation:" -ForegroundColor Cyan
    Write-Host "  • DEPLOYMENT_GUIDE.md" -ForegroundColor White
    Write-Host "  • AZURE_PORTAL_GUIDE.md" -ForegroundColor White
    Write-Host "  • FINAL_DEPLOYMENT_SUMMARY.md" -ForegroundColor White
    Write-Host "`n📝 Deployment log saved to: $LogFile" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# MAIN DEPLOYMENT FLOW
# ============================================================================

function Main {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     Azure Infrastructure Deployment Script            ║" -ForegroundColor Cyan
    Write-Host "║     Application Gateway + Container Apps              ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    $startTime = Get-Date

    try {
        # Step 1: Check prerequisites
        Test-Prerequisites

        # Step 2: Deploy base layer
        Deploy-Terraform -LayerPath "azure-terrafrom\layers\100_base\env\prod" -LayerName "Base Layer (100_base)"

        # Step 3: Setup SSL certificate
        Setup-SSLCertificate

        # Step 4: Deploy backend layer
        Deploy-Terraform -LayerPath "azure-terrafrom\layers\400_backend\env\prod" -LayerName "Backend Layer (400_backend)"

        # Step 5: Build and deploy sample API
        Deploy-SampleAPI

        # Step 6: Verify deployment
        Test-Deployment

        # Calculate deployment time
        $endTime = Get-Date
        $duration = $endTime - $startTime
        $minutes = [math]::Floor($duration.TotalMinutes)
        $seconds = $duration.Seconds

        Write-Success "Total deployment time: ${minutes}m ${seconds}s"

        # Step 7: Display summary
        Show-Summary

    } catch {
        Write-Error-Custom "Deployment failed! Check $LogFile for details."
        Write-Error-Custom $_.Exception.Message
        exit 1
    }
}

# Run main function
Main
