# 500_frontend

output "static_web_app_token" {
  value     = module.static_web_app.web_app_token
  sensitive = true
}