# tfstate module

locals {
  # Region abbreviation
  reg = var.region == "East US" ? "eus" : "cus"
}

resource "azurerm_resource_group" "tfstate" {
  name     = "rg-ztf-tfstate-${var.env}-${local.reg}-001"
  location = var.region
}

resource "azurerm_resource_group" "backend" {
  name     = upper("INFRA-${var.env}-BACKEND")
  location = var.region
}

resource "azurerm_resource_group" "storage" {
  name     = upper("INFRA-${var.env}-STORAGE")
  location = var.region
}

resource "azurerm_resource_group" "database" {
  name     = upper("INFRA-${var.env}-DATABASE")
  location = var.region
}

resource "azurerm_resource_group" "misc" {
  name     = upper("INFRA-${var.env}-MISC")
  location = var.region
}

resource "azurerm_resource_group" "frontend" {
  name     = upper("INFRA-${var.env}-FRONTEND")
  location = var.region
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "ztftfstate${var.env}${local.reg}002"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "RAGZRS"
  tags = {
    Env      = var.env
    EnvAcct  = local.EnvAcct
    AppSuite = "tfstate"
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}