variable "subnet_id" {
  type = string
}

variable "public_ip" {
  type = string
}

variable "rg_location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "Env" {
  type        = string
  description = "Enter the specifyed Environment"
  validation {
    condition     = contains(["prod", "uat", "demo2", "demo"], var.Env)
    error_message = "Please enter a valid value from dev uat demo2 prod"
  }
}

variable "targaet_list" {
  type = list(string)
}

variable "counts" {
  type = string
}

locals {
  EnvAcct     = var.Env == "prod" ? "prod" : "nonp"
  gatway_name = "INFRA-apg-appgateway-${var.Env}-${local.location}-${var.counts}"
}

variable "certificate_id" {
  type = string
}

variable "identity_id" {
  type = string
}

locals {
  backend_address_pool_name      = "${local.gatway_name}-beap"
  frontend_port_name1            = "${local.gatway_name}-feport1"
  frontend_port_name2            = "${local.gatway_name}-feport2"
  frontend_ip_configuration_name = "${local.gatway_name}-feip"
  http_setting_name              = "${local.gatway_name}-be-htst"
  listener_name1                 = "${local.gatway_name}-httplstn1"
  listener_name2                 = "${local.gatway_name}-httplstn2"
  request_routing_rule_name1     = "${local.gatway_name}-rqrt1"
  request_routing_rule_name2     = "${local.gatway_name}-rqrt2"
  redirect_configuration_name    = "${local.gatway_name}-rdrcfg"
  ssl_certificate_name           = "${local.gatway_name}-ssl"
}

variable "firewall_policy_id" {
  type = string
}

variable "sku" {
  type = string
  validation {
    condition     = contains(["Standard_v2", "WAF_v2"], var.sku)
    error_message = "SKU must be either Standard_v2 or WAF_v2 for developer tier support"
  }
}

variable "capacity" {
  type        = number
  default     = 2
  description = "Number of instances for the Application Gateway. Use 1 for developer tier."
  validation {
    condition     = var.capacity >= 1 && var.capacity <= 125
    error_message = "Capacity must be between 1 and 125"
  }
}

locals {
  firewall_policy_id = var.sku == "WAF_v2" ? var.firewall_policy_id : null
}

locals {
  first_char     = substr(var.location, 0, 1)
  last_two_chars = substr(var.location, length(var.location) - 2, 2)
  location       = "${local.first_char}${local.last_two_chars}"
}
variable "location" {
  type = string
}