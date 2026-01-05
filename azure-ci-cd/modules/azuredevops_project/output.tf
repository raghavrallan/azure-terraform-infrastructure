output "id" {
  description = "The ID of the Azure DevOps project"
  value       = azuredevops_project.project.id
}

output "name" {
  description = "The name of the Azure DevOps project"
  value       = azuredevops_project.project.name
}
