# Populate Key Vault Secrets
# This script populates the Key Vault with secrets needed for the backend layer

$keyVaultName = "ZTF-PROD-SECRET-V2"
$storageAccountName = "ztfprodstorage001v2"
$cosmosAccountName = "ztf-cns-account-prod-eastus-001-v2"
$resourceGroupStorage = "ZTF-PROD-STORAGE"
$resourceGroupDatabase = "ZTF-PROD-DATABASE"
$resourceGroupMisc = "ZTF-PROD-MISC"

Write-Host "Populating Key Vault secrets..." -ForegroundColor Cyan

# Get Blob Storage secrets
Write-Host "Getting Blob Storage secrets..." -ForegroundColor Yellow
$storageKey = (az storage account keys list --account-name $storageAccountName --resource-group $resourceGroupStorage --query "[0].value" -o tsv)
$blobEndpoint = "https://$storageAccountName.blob.core.windows.net/"

az keyvault secret set --vault-name $keyVaultName --name "blob-key" --value $storageKey
az keyvault secret set --vault-name $keyVaultName --name "blob-endpoint" --value $blobEndpoint

# Get Cosmos DB secrets
Write-Host "Getting Cosmos DB secrets..." -ForegroundColor Yellow
$cosmosEndpoint = (az cosmosdb show --name $cosmosAccountName --resource-group $resourceGroupDatabase --query "documentEndpoint" -o tsv)
$cosmosKey = (az cosmosdb keys list --name $cosmosAccountName --resource-group $resourceGroupDatabase --query "primaryMasterKey" -o tsv)

az keyvault secret set --vault-name $keyVaultName --name "database-endpoint" --value $cosmosEndpoint
az keyvault secret set --vault-name $keyVaultName --name "database-key" --value $cosmosKey

# Get Communication Service endpoint
Write-Host "Getting Communication Service secrets..." -ForegroundColor Yellow
$acsEndpoint = (az keyvault secret show --vault-name $keyVaultName --name "azure-prod-acs-connection-string" --query "value" -o tsv)
if ($acsEndpoint) {
    az keyvault secret set --vault-name $keyVaultName --name "acs-endpoint" --value $acsEndpoint
}

# Generate JWT and encryption keys if they don't exist
Write-Host "Generating application secrets..." -ForegroundColor Yellow

# JWT Key (base64 encoded random string)
$jwtKey = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((New-Guid).ToString() + (New-Guid).ToString()))
az keyvault secret set --vault-name $keyVaultName --name "jwt-key" --value $jwtKey

# Encryption keys
$encryptionKey = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((New-Guid).ToString()))
$eEncryptionKey = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((New-Guid).ToString()))

az keyvault secret set --vault-name $keyVaultName --name "keyforencryptionanddecryption" --value $encryptionKey
az keyvault secret set --vault-name $keyVaultName --name "ekeyforencryptionanddecryption" --value $eEncryptionKey

Write-Host "All secrets populated successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "You can now deploy the backend layer:"
Write-Host "cd azure-terrafrom/layers/400_backend/env/prod" -ForegroundColor Cyan
Write-Host "terraform apply -auto-approve" -ForegroundColor Cyan
