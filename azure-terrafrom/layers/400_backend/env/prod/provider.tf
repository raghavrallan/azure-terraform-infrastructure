# 600_backend

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.56.0"
    }
  }
  # WARNING: This has to be hardcoded because
  # variable resoultion is not allowed in the
  # terraform block.
  backend "azurerm" {
    resource_group_name  = "rg-ztf-tfstate-prod-eus-001"
    storage_account_name = "ztftfstateprodeus002"
    container_name       = "tfstate"
    key                  = "terraform_prod_eus_400_backend.tfstate"
  }

}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
