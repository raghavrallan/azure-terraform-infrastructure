resource "azurerm_role_assignment" "role_assignment" {
  scope                = var.resource_id
  role_definition_name = var.permission
  principal_id         = var.object_id
}