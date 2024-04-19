#----------------------------------------
# Loadbalancer & Listener
#----------------------------------------
resource "aws_lb" "api_server" {
  name = "${local.common_name_prefix}-apiserver-lb-${var.environment}"
  # internal                         = true
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true

  security_groups = [aws_security_group.apiserver_lb.id]
  subnets         = [for subnet_id in var.public_subnet_ids : subnet_id]

  tags = {
    Name = "${local.common_name_prefix}-apiserver-lb-${var.environment}"
  }
}

resource "aws_lb_listener" "k8s_server_listener" {
  load_balancer_arn = aws_lb.api_server.arn

  protocol = "TCP"
  port     = var.apiserver_port

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_control_plane.arn
  }

  tags = {
    Name = "${local.common_name_prefix}-apiserver-listener-${var.environment}"
  }
}

#----------------------------------------
# Target group
#----------------------------------------
resource "aws_lb_target_group" "k8s_control_plane" {
  port               = var.apiserver_port
  protocol           = "TCP"
  vpc_id             = var.vpc_id
  preserve_client_ip = false

  health_check {
    protocol = "TCP"
    interval = 10
  }

  tags = {
    Name = "${local.common_name_prefix}-apiserver-targetgroup-${var.environment}"
  }
}

resource "aws_lb_target_group_attachment" "k8s_master_nodes" {
  count = var.master_nodes_count

  target_group_arn = aws_lb_target_group.k8s_control_plane.arn
  target_id        = module.control-plane-node[count.index].id
  port             = var.apiserver_port
}
