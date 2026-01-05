data "terraform_remote_state" "base" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-ztf-tfstate-uat-eus-001"
    storage_account_name = "ztftfstateuateus001"
    container_name       = "tfstate"
    key                  = "terraform_uat_eus_100_base.tfstate"
  }
}

data "terraform_remote_state" "backend" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-ztf-tfstate-uat-eus-001"
    storage_account_name = "ztftfstateuateus001"
    container_name       = "tfstate"
    key                  = "terraform_uat_eus_400_backend.tfstate"
  }
}

data "terraform_remote_state" "frontend" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-ztf-tfstate-uat-eus-001"
    storage_account_name = "ztftfstateuateus001"
    container_name       = "tfstate"
    key                  = "terraform_uat_eus_500_frontend.tfstate"
  }
}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}


data "azurerm_key_vault_secret" "github_token" {
  name         = "github-pat"
  key_vault_id = data.terraform_remote_state.base.outputs.key_vault_id
}

data "azurerm_key_vault_secret" "pipeline_token" {
  name         = "pipeline-pat"
  key_vault_id = data.terraform_remote_state.base.outputs.key_vault_id
}