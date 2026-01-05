# 200_tenant_storage

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
    resource_group_name  = "rg-ztf-tfstate-uat-eus-001"
    storage_account_name = "ztftfstateuateus001"
    container_name       = "tfstate"
    key                  = "terraform_uat_eus_200_tenant_storage.tfstate"
  }

}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
