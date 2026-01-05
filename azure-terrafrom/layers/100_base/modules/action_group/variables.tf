variable "Env" {
  type        = string
  description = "Enter the specifyed Environment"
  validation {
    condition     = contains(["prod", "uat", "staging"], var.Env)
    error_message = "Please enter a valid value from dev uat uat prod"
  }
}

variable "rg_name" {
  type = string
}

locals {
  EnvAcct = var.Env == "prod" ? "prod" : "nonp"
}

variable "counts" {
  type = string
}

variable "email" {
  type = list(object({
    reciver_name  = string
    reciver_email = string
  }))
}
