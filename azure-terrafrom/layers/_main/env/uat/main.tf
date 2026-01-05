# _main

module "tfstate" {
  source = "../../modules/tfstate"
  env    = var.env
  region = var.region
}
