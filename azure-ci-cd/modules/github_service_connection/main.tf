resource "azuredevops_serviceendpoint_github" "github" {
  project_id            = var.project_id
  service_endpoint_name = var.service_endpoint_name

  auth_personal {
    personal_access_token = var.github_token
  }
}
