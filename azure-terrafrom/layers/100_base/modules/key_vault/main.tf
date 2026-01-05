resource "azurerm_key_vault" "key_vault" {
  name                        = "ZTF-${upper(var.Env)}-SECRET-V2"
  location                    = var.rg_location
  resource_group_name         = var.rg_name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id #data.azurerm_client_config.current.tenant_id
  purge_protection_enabled    = true
  soft_delete_retention_days  = 7
  sku_name                    = "standard"

  tags = {
    Env     = var.Env
    EnvAcct = local.EnvAcct

    AppSuite = "keyvault"
  }
}

resource "azurerm_user_assigned_identity" "identity" {
  name                = "ZTF-${var.Env}-managed-identity"
  resource_group_name = var.rg_name
  location            = var.rg_location
  tags = {

    AppSuite = "managed_identity"
    Env      = var.Env
    EnvAcct  = local.EnvAcct
  }
}

resource "azurerm_key_vault_access_policy" "access_to_identity" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = var.tenant_id
  object_id    = azurerm_user_assigned_identity.identity.principal_id

  secret_permissions      = ["Get", "List"]
  certificate_permissions = ["Get"]
}

resource "azurerm_key_vault_access_policy" "access" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = var.tenant_id
  object_id    = var.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Backup",
    "Recover",
    "Restore",
  ]

  key_permissions = [
    "Get",
    "Create",
    "Delete",
    "List",
    "Update",
    "Import",
    "Backup",
    "Recover",
    "Restore",
  ]

  storage_permissions = [
    "Get",
    "List",
    "Delete",
    "Set",
    "Update",
    "RegenerateKey",
    "Recover",
    "Purge",
  ]
  certificate_permissions = [
    "List",
    "Get",
    "Backup",
    "Create",
    "GetIssuers",
    "Import",
    "ListIssuers",
    "ManageContacts",
    "ManageIssuers",
    "Recover",
    "Restore",
    "SetIssuers",
    "Update"
  ]

}