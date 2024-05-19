#----------------------------------------
# Load Balancer Ports
#----------------------------------------
resource "aws_security_group" "loadbalancer" {
  name        = "API server Loadbalancer Ports"
  description = "Firewall rules for api server loadbalancer"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = [22, var.apiserver_port]
    content {
      description = "connections to Loadbalancer server from outside"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "ingress" {
    for_each = var.install_ingress_controller ? [80, 443] : []
    content {
      description = "HTTP/HTTPS connections to ingress"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

}

#----------------------------------------
# Cluster Nodes Ports
#----------------------------------------
resource "aws_security_group" "k8s-nodes" {
  name        = "K8S Nodes Ports"
  description = "Firewall rules for k8s Nodes"
  vpc_id      = var.vpc_id

  ingress {
    description = "ingress traffic from k8s nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  dynamic "ingress" {
    for_each = var.install_ingress_controller ? [22, var.apiserver_port, var.ingress_http_nodePort, var.ingress_https_nodePort] : [22, var.apiserver_port]
    content {
      description     = "Connections from Loadbalancer"
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.loadbalancer.id]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

}
