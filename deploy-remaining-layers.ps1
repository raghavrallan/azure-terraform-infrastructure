# Deploy Remaining Infrastructure Layers
# This script deploys the remaining Terraform layers after _main and 100_base

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Deploying Remaining Infrastructure Layers" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Function to deploy a layer
function Deploy-Layer {
    param (
        [string]$LayerPath,
        [string]$LayerName
    )

    Write-Host "------------------------------------------------" -ForegroundColor Yellow
    Write-Host "Deploying Layer: $LayerName" -ForegroundColor Yellow
    Write-Host "------------------------------------------------" -ForegroundColor Yellow

    Push-Location $LayerPath

    # Initialize if needed
    Write-Host "Initializing Terraform..." -ForegroundColor Cyan
    terraform init -reconfigure
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Terraform init failed for $LayerName" -ForegroundColor Red
        Pop-Location
        return $false
    }

    # Plan
    Write-Host "Creating Terraform plan..." -ForegroundColor Cyan
    terraform plan -out="${LayerName}.tfplan"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Terraform plan failed for $LayerName" -ForegroundColor Red
        Pop-Location
        return $false
    }

    # Apply
    Write-Host "Applying Terraform configuration..." -ForegroundColor Cyan
    terraform apply "${LayerName}.tfplan"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Terraform apply failed for $LayerName" -ForegroundColor Red
        Pop-Location
        return $false
    }

    Write-Host "SUCCESS: $LayerName deployed successfully!" -ForegroundColor Green
    Write-Host ""

    Pop-Location
    return $true
}

# Deploy layers in order
$layers = @(
    @{
        Path = "azure-terrafrom\layers\200_tenant_storage\env\prod"
        Name = "200_tenant_storage"
    },
    @{
        Path = "azure-terrafrom\layers\300_database\env\prod"
        Name = "300_database"
    },
    @{
        Path = "azure-terrafrom\layers\400_backend\env\prod"
        Name = "400_backend"
    }
)

$failedLayers = @()

foreach ($layer in $layers) {
    $success = Deploy-Layer -LayerPath $layer.Path -LayerName $layer.Name
    if (-not $success) {
        $failedLayers += $layer.Name
        Write-Host "WARNING: Deployment failed for $($layer.Name). Continuing with next layer..." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 2
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if ($failedLayers.Count -eq 0) {
    Write-Host "All layers deployed successfully!" -ForegroundColor Green
} else {
    Write-Host "The following layers failed to deploy:" -ForegroundColor Red
    foreach ($failed in $failedLayers) {
        Write-Host "  - $failed" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "To check deployment status, run:" -ForegroundColor Cyan
Write-Host "  cd azure-terrafrom\layers\400_backend\env\prod" -ForegroundColor White
Write-Host "  terraform output" -ForegroundColor White
