variable "counts" {
  type = string
}

variable "target_id" {
  type = string
}

variable "storage_account_id" {
  type    = string
  default = null
}


variable "log_analytics_id" {
  type = string
}

variable "Env" {
  type        = string
  description = "Enter the specifyed Environment"
  validation {
    condition     = contains(["prod", "uat", "staging"], var.Env)
    error_message = "Please enter a valid value from dev uat uat prod"
  }
}

variable "enable_logs" {
  type    = string
  default = true
}

variable "metric" {
  type    = string
  default = null
}

variable "enable_mertic" {
  type    = bool
  default = true
}

variable "location" {
  type = string
}

locals {
  first_char     = substr(var.location, 0, 1)
  last_two_chars = substr(var.location, length(var.location) - 2, 2)
  location       = "${local.first_char}${local.last_two_chars}"
}