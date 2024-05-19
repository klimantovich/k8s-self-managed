# provider "helm" {
#   kubernetes {
#     config_path = "~/.kube/config"
#   }
# }

# provider "kubectl" {
#   host                   = "https://${module.cluster.cluster_endpoint}"
#   cluster_ca_certificate = module.cluster.ca_certificate
# }

# provider "google" {
#   project = var.gcp_project
# }
