output "cluster_security_group_id" {
  description = "Cluster security group id"
  value       = aws_security_group.k8s-nodes.id
}

output "cluster_ip" {
  description = "Cluster public IP address"
  value       = module.loadbalancer.public_ip
}

output "cluster_endpoint" {
  description = "Cluster endpoint"
  value       = "${module.loadbalancer.public_ip}:${var.apiserver_port}"
}

output "ingress_endpoint" {
  description = "Cluster endpoint"
  value       = var.install_ingress_controller ? "https://${module.loadbalancer.public_ip}" : null
}

# output "ca_certificate" {
#   description = "Cluster CA hash certificate"
#   value       = data.aws_secretsmanager_secret_version.ca_certificate.secret_string
# }
