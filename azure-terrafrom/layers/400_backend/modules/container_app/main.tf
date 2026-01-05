resource "azurerm_container_app" "container_app" {
  name                         = "ztf-cap-container-${var.Env}-${local.location}-${var.counts}"
  container_app_environment_id = var.app_environment_id
  resource_group_name          = var.rg_name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  registry {
    server               = var.acr_server
    username             = var.acr_username
    password_secret_name = "acr-password"
  }

  dynamic "secret" {
    for_each = { for idx, s in var.container_secrets : idx => s }
    iterator = secret_item

    content {
      name                = secret_item.value.name
      value               = lookup(secret_item.value, "value", null)
      key_vault_secret_id = lookup(secret_item.value, "key_vault_secret_id", null)
      identity            = lookup(secret_item.value, "identity", null)
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    custom_scale_rule {
      name             = "cputhreshold"
      custom_rule_type = "cpu"
      metadata = {
        type  = "Utilization"
        value = 70
      }
    }
    container {
      name   = "ztf-cap-container-${var.Env}-${local.location}-${var.counts}"
      image  = var.image
      cpu    = var.container_cpu
      memory = var.container_memory

      dynamic "env" {
        for_each = var.environment_variable
        iterator = env_item

        content {
          name        = env_item.value.name
          value       = try(env_item.value.value, null)
          secret_name = try(env_item.value.secret_name, null)
        }
      }
    }

  }

  ingress {
    target_port      = var.container_port
    external_enabled = var.external_enabled

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = var.identity_ids
  }

  tags = {
    Env      = var.Env
    EnvAcct  = local.EnvAcct
    AppSuite = "container_app"
  }
}