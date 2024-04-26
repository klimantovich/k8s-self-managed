locals {
  db_identifier        = "${var.environment}-mysql-master"
  db_subnet_group_name = "${var.environment}-db-subnet-group"
}

module "database" {
  source = "git@github.com:klimantovich/itransition-devops-tasks.git"

  environment = var.environment

  # security group variables
  security_group_vpc_id         = module.k8s_vpc.vpc_id
  security_group_db_port        = var.security_group_db_port
  db_ingress_security_group_ids = [module.cluster.cluster_security_group_id] # Acess from EKS cluster

  # instance variables
  db_allocated_storage   = var.db_allocated_storage
  database_name          = var.db_name
  db_identifier          = local.db_identifier
  db_engine              = var.db_engine
  db_engine_version      = var.db_engine_version
  db_instance_class      = var.db_instance_class
  db_password            = random_password.db_password.result
  db_skip_final_snapshot = var.db_skip_final_snapshot
  db_username            = var.db_user

  # subnet group variables
  subnet_group_name       = local.db_subnet_group_name
  subnet_group_subnet_ids = module.k8s_vpc.private_subnet_ids

}
