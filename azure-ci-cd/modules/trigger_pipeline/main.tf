
resource "azuredevops_build_definition" "trigger_pipeline" {
  project_id = var.project_id
  name       = "${upper(var.Env)}-ZTF-${var.app_suite} (${var.tech})"
  path       = "\\"

  ci_trigger {
    use_yaml = var.trigger
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo
    branch_name           = var.github_branch
    yml_path              = var.ymlpath
    service_connection_id = var.service_connection_id
  }

  dynamic "variable" {
    for_each = var.environment_variable
    content {
      name  = variable.value.name
      value = variable.value.secret_value
    }
  }
}
