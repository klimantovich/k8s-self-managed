output "ingress_url" {
  description = "URL of application ingress"
  value       = module.cluster.ingress_endpoint
}

output "http_auth_password" {
  description = "Application HTTP Auth password"
  value       = nonsensitive(aws_secretsmanager_secret_version.nginx_password.secret_string)
}
