data "terraform_remote_state" "base" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-ztf-tfstate-prod-eus-001"
    storage_account_name = "ztftfstateprodeus002"
    container_name       = "tfstate"
    key                  = "terraform_prod_eus_100_base.tfstate"
  }
}


# Commented out - resources destroyed
# data "azurerm_key_vault_secret" "blob_key" {
#   name         = "blob-key"
#   key_vault_id = data.terraform_remote_state.base.outputs.key_vault_id
# }

# data "azurerm_key_vault_secret" "blob_endpoint" {
#   name         = "blob-endpoint"
#   key_vault_id = data.terraform_remote_state.base.outputs.key_vault_id
# }

# data "azurerm_key_vault_secret" "acs_endpoint" {
#   name         = "acs-endpoint"
#   key_vault_id = data.terraform_remote_state.base.outputs.key_vault_id
# }

# data "azurerm_key_vault_secret" "database_endpoint" {
#   name         = "database-endpoint"
#   key_vault_id = data.terraform_remote_state.base.outputs.key_vault_id
# }

# data "azurerm_key_vault_secret" "database_key" {
#   name         = "database-key"
#   key_vault_id = data.terraform_remote_state.base.outputs.key_vault_id
# }

# data "azurerm_key_vault_secret" "jwt_key" {
#   name         = "jwt-key"
#   key_vault_id = data.terraform_remote_state.base.outputs.key_vault_id
# }

# data "azurerm_key_vault_secret" "ekeyforencryptionanddecryption" {
#   name         = "ekeyforencryptionanddecryption"
#   key_vault_id = data.terraform_remote_state.base.outputs.key_vault_id
# }

# data "azurerm_key_vault_secret" "keyforencryptionanddecryption" {
#   name         = "keyforencryptionanddecryption"
#   key_vault_id = data.terraform_remote_state.base.outputs.key_vault_id
# }