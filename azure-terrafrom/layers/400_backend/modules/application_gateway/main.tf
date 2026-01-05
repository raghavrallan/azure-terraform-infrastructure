resource "azurerm_application_gateway" "gateway" {
  name                = local.gatway_name
  resource_group_name = var.rg_name
  location            = var.rg_location
  firewall_policy_id  = local.firewall_policy_id

  sku {
    name     = var.sku
    tier     = var.sku
    capacity = var.capacity
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = local.frontend_port_name1
    port = 443
  }

  frontend_port {
    name = local.frontend_port_name2
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = var.public_ip
  }

  backend_address_pool {
    name  = local.backend_address_pool_name
    fqdns = var.targaet_list
  }

  backend_http_settings {
    name                                = local.http_setting_name
    cookie_based_affinity               = "Disabled"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 60
    pick_host_name_from_backend_address = true
    probe_name                          = "main-prob"
  }

  ssl_certificate {
    name                = local.ssl_certificate_name
    key_vault_secret_id = var.certificate_id
  }

  http_listener {
    name                           = local.listener_name1
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name1
    protocol                       = "Https"
    ssl_certificate_name           = local.ssl_certificate_name
  }

  http_listener {
    name                           = local.listener_name2
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name2
    protocol                       = "Http"
  }

  redirect_configuration {
    name                 = local.redirect_configuration_name
    redirect_type        = "Permanent"
    target_listener_name = local.listener_name1
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name1
    priority                   = 1
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name1
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  request_routing_rule {
    name                        = local.request_routing_rule_name2
    priority                    = 2
    rule_type                   = "Basic"
    redirect_configuration_name = local.redirect_configuration_name
    http_listener_name          = local.listener_name2
  }

  probe {
    interval                                  = 30
    name                                      = "main-prob"
    protocol                                  = "Http"
    path                                      = "/"
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
    match {
      status_code = ["200-399"]
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  tags = {
    Env      = var.Env
    EnvAcct  = local.EnvAcct
    AppSuite = "app_gateway"
  }
}