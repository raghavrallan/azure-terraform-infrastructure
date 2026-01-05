
module "azure_devops_project" {
  source = "../../modules/azuredevops_project"
  Env    = var.Env
}

module "github_service_connection" {
  source                = "../../modules/github_service_connection"
  project_id            = module.azure_devops_project.id
  service_endpoint_name = "Github Service Endpoint"
  github_token          = data.azurerm_key_vault_secret.github_token.value
}

module "frontend" {
  source                = "../../modules/trigger_pipeline"
  project_id            = module.azure_devops_project.id
  Env                   = var.Env
  app_suite             = "Frontend"
  tech                  = "React"
  trigger               = false
  github_repo           = "YourOrg/frontend-app"
  github_branch         = "uat"
  ymlpath               = "azure/uat-pipeline.yml"
  service_connection_id = module.github_service_connection.id
  environment_variable = [
    {
      name         = "STATIC_WEB_APP_TOKEN"
      secret_value = data.terraform_remote_state.frontend.outputs.static_web_app_token
    }
  ]
}

module "backend" {
  source                = "../../modules/trigger_pipeline"
  project_id            = module.azure_devops_project.id
  Env                   = var.Env
  app_suite             = "Backend"
  tech                  = "dotnet"
  trigger               = false
  github_repo           = "YourOrg/backend-app"
  github_branch         = "uat"
  ymlpath               = "azure/uat_pipeline.yml"
  service_connection_id = module.github_service_connection.id
  environment_variable = [
    {
      name         = "ACR_NAME"
      secret_value = data.terraform_remote_state.backend.outputs.acr_name
    },
    {
      name         = "ACR_PASSWORD"
      secret_value = data.terraform_remote_state.backend.outputs.acr_password
    },
    {
      name         = "CONTAINER_APP_NAME"
      secret_value = data.terraform_remote_state.backend.outputs.container_app_name
    },
    {
      name         = "RG_NAME"
      secret_value = "INFRA-UAT-BACKEND"
    }
  ]
}