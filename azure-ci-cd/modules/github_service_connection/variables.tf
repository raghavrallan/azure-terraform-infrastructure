variable "project_id" {
  description = "The ID of the Azure DevOps project where the service connection will be created."
  type        = string
}

variable "service_endpoint_name" {
  description = "The name of the GitHub service connection in Azure DevOps."
  type        = string
}

variable "github_token" {
  description = "The GitHub Personal Access Token (PAT) used for authentication."
  type        = string
  sensitive   = true
}
