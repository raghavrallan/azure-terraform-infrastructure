# 200_datalake

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.56.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "1.12.2"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-ztf-tfstate-prod-eus-001"
    storage_account_name = "stztftfstatztfrodeus001"
    container_name       = "tfstate"
    key                  = "terraform_prod_azure_ci_cd.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azuredevops" {
  org_service_url       = var.org_service_url
  personal_access_token = data.azurerm_key_vault_secret.pipeline_token.value
}