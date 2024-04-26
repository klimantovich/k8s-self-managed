aws_region  = "us-west-2"
environment = "dev"
vpc_cidr    = "172.16.0.0/16"

master_nodes_count          = 3
worker_nodes_count          = 2
cluster_instances_ami       = "ami-08116b9957a259459"
loadbalancer_instances_type = "t2.micro"
master_instances_type       = "t2.medium"
worker_instances_type       = "t2.small"
cluster_kubernetes_version  = "1.29"
install_ingress_controller  = true

security_group_db_port = 3306
db_allocated_storage   = 10
db_engine              = "mysql"
db_engine_version      = "5.7"
db_instance_class      = "db.t3.small"
db_skip_final_snapshot = true

argocd_chart_create_namespace = true
argocd_chart_namespace        = "argocd"
argocd_chart_version          = "5.46.2"
argocd_values_path            = "./manifests/argocd-config.yaml"
argocd_project_name           = "main-project"

project_application_name  = "gym-management-app"
project_repository        = "https://github.com/klimantovich/us-west-1-cluster"
project_repository_branch = "HEAD"
project_repository_path   = "charts/gymmanagement"
project_namespace         = "gymmanagement"

telegram_bot_app_file = "tgbot-notifier.zip"
gcp_project           = "disco-freedom-409407"
tgbot_secret_name     = "tg_bot_token"
telegram_bot_chat_id  = "6325914269"

db_name      = "Gym"
db_user      = "root"
httpAuthUser = "vitali"

