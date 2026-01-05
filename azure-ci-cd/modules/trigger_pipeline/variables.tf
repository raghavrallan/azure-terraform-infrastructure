variable "Env" {
  type        = string
  description = "Enter the specifyed Environment"
  validation {
    condition     = contains(["PROD", "UAT"], var.Env)
    error_message = "Please enter a valid value from uat prod"
  }
}

variable "ymlpath" {
  type = string
}

variable "github_branch" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "project_id" {
  type = string
}

variable "service_connection_id" {
  type = string
}

variable "environment_variable" {
  type = list(object({
    name         = string
    secret_value = string
  }))
}

variable "trigger" {
  type = bool
}

variable "app_suite" {
  type = string
}

variable "tech" {
  type = string
}