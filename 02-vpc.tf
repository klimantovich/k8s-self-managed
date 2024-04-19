module "k8s_vpc" {
  source = "./modules/aws-network"

  aws_region  = var.aws_region
  vpc_cidr    = var.vpc_cidr
  environment = var.environment

}
