variable "allowed_actions" {
  type = list(string)
}

variable "denyed_actions" {
  type    = list(string)
  default = []
}

variable "subscription_id" {
  type = string
}

variable "role_description" {
  type = string
}

variable "role_name" {
  type = string
}

variable "Env" {
  type = string
}