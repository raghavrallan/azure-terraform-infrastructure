# 500_frontend

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.46.0"
    }
  }
  # WARNING: This has to be hardcoded because
  # variable resoultion is not allowed in the
  # terraform block.
  backend "azurerm" {
    resource_group_name  = "rg-ztf-tfstate-prod-eus-001"
    storage_account_name = "ztftfstateprodeus002"
    container_name       = "tfstate"
    key                  = "terraform_prod_eus_500_frontend.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
