resource "azurerm_role_definition" "role" {
  name        = "ZTF-${var.Env}-${var.role_name}"
  description = var.role_description
  scope       = "/subscriptions/${var.subscription_id}"

  permissions {
    actions     = var.allowed_actions
    not_actions = var.denyed_actions
  }
  assignable_scopes = ["/subscriptions/${var.subscription_id}"]
}