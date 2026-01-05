variable "Env" {
  type        = string
  description = "Enter the specifyed Environment"
  validation {
    condition     = contains(["prod", "uat", "staging"], var.Env)
    error_message = "Please enter a valid value from dev uat uat prod"
  }
}

locals {
  EnvAcct = var.Env == "prod" ? "prod" : "nonp"
}

variable "action_group_id" {
  type = string
}

variable "resource_name" {
  type = string
}

variable "resource_id" {
  type = string
}

variable "description" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "metric_name" {
  type = string
}

variable "metric_namespace" {
  type = string
}

variable "threshold" {
  type = number
}

variable "counts" {
  type = string
}

variable "aggregation" {
  type    = string
  default = "Average"
  validation {
    condition     = contains(["Average", "Count", "Minimum", "Maximum", "Total"], var.aggregation)
    error_message = "Please enter a valid value."
  }
}

variable "operator" {
  type    = string
  default = "GreaterThanOrEqual"
  validation {
    condition     = contains(["Equals", "GreaterThan", "GreaterThanOrEqual", "LessThan", "LessThanOrEqual"], var.operator)
    error_message = "Please enter a valid value."
  }
}

variable "severity" {
  type    = number
  default = 3
  validation {
    condition     = contains([4, 3, 2, 1, 0], var.severity)
    error_message = "Please enter a valid value."
  }
}
