output "cluster_security_group_id" {
  description = "Cluster security group id"
  value       = aws_security_group.k8s-nodes.id
}

output "cluster_endpoint" {
  description = "Cluster endpoint"
  value       = aws_lb.api_server.dns_name
}

# output "ingress_endpoint" {
#   description = "k8s Ingress AWS ELB endpoint"
#   value       = data.kubernetes_service.ingress_nginx.status.0.load_balancer.0.ingress.0.hostname
# }
# output "ingress_endpoint" {
#   description = "k8s Ingress AWS ELB endpoint"
#   value       = data.kubernetes_service.ingress_nginx.status.0.load_balancer.0.ingress.0.hostname
# }
