module "control-plane-node" {
  source = "../aws-ec2"
  count  = var.master_nodes_count

  ec2_ami           = var.instances_ami
  ec2_instance_type = var.master_instance_type
  ec2_private_ip    = join(".", [local.master_nodes_subnet_prefix, count.index + 10])
  ec2_subnet_id     = local.master_nodes_subnet # Control Plane Subnet

  ec2_vpc_security_group_ids = [aws_security_group.k8s-nodes.id]
  ec2_key_name               = aws_key_pair.cluster.key_name
  ec2_iam_instance_profile   = aws_iam_instance_profile.k8s-control-node.name

  ec2_user_data = data.template_cloudinit_config.k8s_master.rendered

  ec2_instance_tags = {
    Name = "${local.common_name_prefix}-master-${count.index + 1}"
    role = "master"
  }

  depends_on = [aws_lb.api_server]

}

module "worker-node" {
  source = "../aws-ec2"
  count  = var.worker_nodes_count

  ec2_ami           = var.instances_ami
  ec2_instance_type = var.worker_instance_type
  ec2_private_ip    = join(".", [local.worker_nodes_subnet_prefix, count.index + 10])
  ec2_subnet_id     = local.worker_nodes_subnet # Worker nodes Subnet

  ec2_vpc_security_group_ids = [aws_security_group.k8s-nodes.id]
  ec2_key_name               = aws_key_pair.cluster.key_name
  ec2_iam_instance_profile   = aws_iam_instance_profile.k8s-worker-node.name

  ec2_user_data = data.template_cloudinit_config.k8s_worker.rendered

  ec2_instance_tags = {
    Name = "${local.common_name_prefix}-worker-${count.index + 1}"
    role = "worker"
  }

  depends_on = [aws_lb.api_server]

}
