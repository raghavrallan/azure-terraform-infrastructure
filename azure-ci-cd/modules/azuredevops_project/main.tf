resource "azuredevops_project" "project" {
  name               = "ZTF-${var.Env}"
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Agile"
}

