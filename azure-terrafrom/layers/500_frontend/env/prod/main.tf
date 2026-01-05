# 500_frontend

module "static_web_app" {
  source  = "../../modules/static_web_app"
  Env     = var.Env
  rg_name = var.rg_name
  counts  = "001"
  sku     = "Free"
}