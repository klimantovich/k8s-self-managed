#----------------------------------------
# Master Nodes
#----------------------------------------
module "master-node" {
  source = "../aws-ec2"
  count  = var.master_nodes_count

  ec2_ami           = var.instances_ami
  ec2_instance_type = var.master_instance_type

  ec2_private_ip             = local.master_nodes_ips[count.index]
  ec2_subnet_id              = local.master_nodes_subnet
  ec2_vpc_security_group_ids = [aws_security_group.k8s-nodes.id]
  ec2_key_name               = aws_key_pair.cluster.key_name
  ec2_iam_instance_profile   = aws_iam_instance_profile.k8s-control-node.name

  # If it's a first master node, start kubeadm-init config, else - kubeadm-join
  ec2_user_data_base64 = count.index == 0 ? base64encode(templatefile("${path.module}/scripts/master-init.yaml.tftpl",
    {
      aws_default_region                  = var.aws_region
      kubernetes_version                  = var.kubernetes_version
      crio_version                        = var.crio_version
      calico_version                      = var.calico_version
      advertiseAddress                    = local.master_nodes_ips[count.index]
      apiserver_port                      = var.apiserver_port
      control_plane_endpoint              = module.loadbalancer.public_ip
      pod_subnet_cidr                     = var.pod_subnet_cidr
      service_subnet_cidr                 = var.service_subnet_cidr
      install_ingress_controller          = var.install_ingress_controller
      ingress_http_nodePort               = var.ingress_http_nodePort
      ingress_https_nodePort              = var.ingress_https_nodePort
      kubeadm_ca_secret_name              = local.kubeadm_ca_secret_name
      kubeadm_ca_hash_secret_name         = local.kubeadm_ca_hash_secret_name
      kubeadm_certificate_key_secret_name = local.kubeadm_certificate_key_secret_name
      kubeadm_token_secret_name           = local.kubeadm_token_secret_name
      kubeconfig_secret_name              = local.kubeconfig_secret_name
    }
    )) : base64encode(templatefile("${path.module}/scripts/master-join.yaml.tftpl",
    {
      aws_default_region                  = var.aws_region
      kubernetes_version                  = var.kubernetes_version
      crio_version                        = var.crio_version
      apiserver_port                      = var.apiserver_port
      control_plane_endpoint              = module.loadbalancer.public_ip
      kubeadm_certificate_key_secret_name = local.kubeadm_certificate_key_secret_name
      kubeadm_token_secret_name           = local.kubeadm_token_secret_name
      kubeadm_ca_hash_secret_name         = local.kubeadm_ca_hash_secret_name
      secret_placeholder                  = local.secret_placeholder
    }
  ))

  ec2_instance_tags = {
    Name = "${local.common_name_prefix}-master-${count.index}"
    Role = "Control Plane"
  }

  depends_on = [module.loadbalancer]
}

#----------------------------------------
# Worker Nodes
#----------------------------------------
module "worker-node" {
  source = "../aws-ec2"
  count  = var.worker_nodes_count

  ec2_ami           = var.instances_ami
  ec2_instance_type = var.worker_instance_type

  ec2_private_ip             = local.worker_nodes_ips[count.index]
  ec2_subnet_id              = local.worker_nodes_subnet
  ec2_vpc_security_group_ids = [aws_security_group.k8s-nodes.id]
  ec2_key_name               = aws_key_pair.cluster.key_name
  ec2_iam_instance_profile   = aws_iam_instance_profile.k8s-worker-node.name

  # If it's a first master node, start kubeadm-init config, else - kubeadm-join
  ec2_user_data_base64 = base64encode(templatefile("${path.module}/scripts/worker-join.yaml.tftpl",
    {
      aws_default_region                  = var.aws_region
      kubernetes_version                  = var.kubernetes_version
      crio_version                        = var.crio_version
      apiserver_port                      = var.apiserver_port
      control_plane_endpoint              = module.loadbalancer.public_ip
      kubeadm_ca_hash_secret_name         = local.kubeadm_ca_hash_secret_name
      kubeadm_certificate_key_secret_name = local.kubeadm_certificate_key_secret_name
      kubeadm_token_secret_name           = local.kubeadm_token_secret_name
      secret_placeholder                  = local.secret_placeholder
    }
  ))

  ec2_instance_tags = {
    Name = "${local.common_name_prefix}-worker-${count.index}"
    Role = "Worker"
  }

  depends_on = [module.master-node]
}
