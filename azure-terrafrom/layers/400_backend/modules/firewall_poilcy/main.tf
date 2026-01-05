resource "azurerm_web_application_firewall_policy" "firewall" {
  name                = "ZTF-waf-firewall-${var.Env}-${local.location}-${var.counts}"
  resource_group_name = var.rg_name
  location            = var.rg_location

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  tags = {
    Env      = var.Env
    EnvAcct  = local.EnvAcct
    AppSuite = "firewall"
  }
}