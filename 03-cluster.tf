module "k8s_cluster" {
  source = "./modules/k8s-self-managed"

  aws_region = var.aws_region

  private_subnet_ids   = module.k8s_vpc.private_subnet_ids
  private_subnet_cidrs = module.k8s_vpc.private_subnet_cidrs
  public_subnet_ids    = module.k8s_vpc.public_subnet_ids
  vpc_id               = module.k8s_vpc.vpc_id

  master_nodes_count         = var.master_nodes_count
  worker_nodes_count         = var.worker_nodes_count
  instances_ami              = var.cluster_instances_ami
  master_instance_type       = var.master_instances_type
  worker_instance_type       = var.worker_instances_type
  install_ingress_controller = var.ingress_enabled
  kubernetes_version         = var.cluster_kubernetes_version

}
