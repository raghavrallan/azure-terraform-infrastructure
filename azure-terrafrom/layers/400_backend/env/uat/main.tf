# 400_backend

module "container_registry_001" {
  source      = "../../modules/container_registry"
  Env         = var.Env
  counts      = "001"
  rg_name     = var.rg_name
  rg_location = var.rg_location
  sku_name    = "Basic"
}

module "container_app_environment_001" {
  source                = "../../modules/container_environment"
  Env                   = var.Env
  counts                = "001"
  rg_name               = var.rg_name
  rg_location           = var.rg_location
  log_analytics_id      = data.terraform_remote_state.base.outputs.log_analytics_id
  subnet_id             = data.terraform_remote_state.base.outputs.container_app_subnet_id
  new_rg                = "${var.rg_name}-CA"
  workload_profile_type = "Consumption"
}

module "container_app_001" {
  source             = "../../modules/container_app"
  Env                = var.Env
  counts             = "001"
  rg_name            = var.rg_name
  acr_password       = module.container_registry_001.admin_password
  acr_username       = module.container_registry_001.admin_username
  acr_server         = module.container_registry_001.login_server
  container_cpu      = "0.5"
  container_memory   = "1Gi"
  max_replicas       = 4
  min_replicas       = 1
  location           = var.rg_location
  identity_ids       = [data.terraform_remote_state.base.outputs.identity_id]
  container_port     = 80
  image              = "nginx"
  app_environment_id = module.container_app_environment_001.id

  container_secrets = [
    {
      name  = "acr-password"
      value = module.container_registry_001.admin_password
    },
    {
      name                = "acs-endpoint"
      key_vault_secret_id = data.azurerm_key_vault_secret.acs_endpoint.id
      identity            = data.terraform_remote_state.base.outputs.identity_id
    },
    {
      name                = "database-endpoint"
      key_vault_secret_id = data.azurerm_key_vault_secret.database_endpoint.id
      identity            = data.terraform_remote_state.base.outputs.identity_id
    },
    {
      name                = "database-key"
      key_vault_secret_id = data.azurerm_key_vault_secret.database_key.id
      identity            = data.terraform_remote_state.base.outputs.identity_id
    },
    {
      name                = "jwt-key"
      key_vault_secret_id = data.azurerm_key_vault_secret.jwt_key.id
      identity            = data.terraform_remote_state.base.outputs.identity_id
    },
    {
      name                = "blob-endpoint"
      key_vault_secret_id = data.azurerm_key_vault_secret.blob_endpoint.id
      identity            = data.terraform_remote_state.base.outputs.identity_id
    },
    {
      name                = "blob-key"
      key_vault_secret_id = data.azurerm_key_vault_secret.blob_key.id
      identity            = data.terraform_remote_state.base.outputs.identity_id
    },
    {
      name                = "ekeyforencryptionanddecryption"
      key_vault_secret_id = data.azurerm_key_vault_secret.ekeyforencryptionanddecryption.id
      identity            = data.terraform_remote_state.base.outputs.identity_id
    },
    {
      name                = "keyforencryptionanddecryption"
      key_vault_secret_id = data.azurerm_key_vault_secret.keyforencryptionanddecryption.id
      identity            = data.terraform_remote_state.base.outputs.identity_id
    },
    {
      name  = "applicaiton-insights-connection-string"
      value = data.terraform_remote_state.base.outputs.application_insight_connection_string
    }
  ]

  environment_variable = [
    {
      name        = "CosmosDb__AccountEndpoint"
      secret_name = "database-endpoint"
    },
    {
      name        = "CosmosDb__AccountKey"
      secret_name = "database-key"
    },
    {
      name  = "CosmosDb__DatabaseName"
      value = "INFRA-uat-db"
    },
    {
      name        = "Jwt__Key"
      secret_name = "jwt-key"
    },
    {
      name        = "Common__keyForEncryptionAndDecryption"
      secret_name = "keyforencryptionanddecryption"
    },
    {
      name        = "Common__ekeyForEncryptionAndDecryption"
      secret_name = "ekeyforencryptionanddecryption"
    },
    {
      name        = "AzureBlobSettings__BlobServiceEndpoint"
      secret_name = "blob-endpoint"
    },
    {
      name        = "AzureBlobSettings__BlobToken"
      secret_name = "blob-key"
    },
    {
      name  = "SeverMode__ServerType"
      value = "azure"
    },
    {
      name  = "SeverMode__AZURE_CLIENT_ID"
      value = data.terraform_remote_state.base.outputs.identity_client_id
    },
    {
      name  = "AzureBlobSettings__ContainerName"
      value = "appdata"
    },
    {
      name  = "EmailSettings__SendEmailStatus"
      value = "true"
    },
    {
      name  = "EmailSettings__SenderEmail"
      value = "noreply@example.com"
    },
    {
      name  = "Common__environment"
      value = "Development"
    },
    {
      name  = "Jwt__RefreshTokenExpirationMinutes"
      value = 720
    },
    {
      name  = "Jwt__AccessTokenExpirationMinutes"
      value = 20
    },
    {
      name  = "Geoapify__ApiKey"
      value = "info"
    },
    {
      name  = "RiskScoreSettings__RecordsToFetch"
      value = 5
    },
    {
      name  = "RiskScoreSettings__Hazmat"
      value = "Hazardous Materials"
    },
    {
      name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
      secret_name = "applicaiton-insights-connection-string"
    }
  ]
}