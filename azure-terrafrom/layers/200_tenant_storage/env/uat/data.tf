data "terraform_remote_state" "base" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-ztf-tfstate-uat-eus-001"
    storage_account_name = "ztftfstateuateus001"
    container_name       = "tfstate"
    key                  = "terraform_uat_eus_100_base.tfstate"
  }
}