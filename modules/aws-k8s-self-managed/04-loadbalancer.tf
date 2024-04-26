module "loadbalancer" {
  source = "../aws-ec2"

  ec2_ami                         = var.instances_ami
  ec2_instance_type               = var.loadbalancer_instances_type
  ec2_associate_public_ip_address = true
  ec2_subnet_id                   = local.loadbalancer_subnet
  ec2_vpc_security_group_ids      = [aws_security_group.loadbalancer.id]
  ec2_key_name                    = aws_key_pair.cluster.key_name

  # ec2_user_data_replace_on_change = true
  ec2_user_data_base64 = base64encode(templatefile("${path.module}/scripts/setup_loadbalancer.yaml.tftpl",
    {
      hostname                   = "loadbalancer"
      apiserver_port             = var.apiserver_port
      master_nodes_ips           = zipmap(range(var.master_nodes_count), local.master_nodes_ips)
      cluster_nodes_ips          = zipmap(range(local.nodes_total_number), local.cluster_nodes_ips)
      install_ingress_controller = var.install_ingress_controller
      ingress_http_nodePort      = var.ingress_http_nodePort
      ingress_https_nodePort     = var.ingress_https_nodePort
    }
  ))

  ec2_instance_tags = {
    Name = "${local.common_name_prefix}-loadbalancer"
  }
}
