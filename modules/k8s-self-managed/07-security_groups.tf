resource "aws_security_group" "apiserver_lb" {
  name        = "API server Loadbalancer Ports"
  description = "Firewall rules for api server loadbalancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "connection to API server from outside"
    from_port   = var.apiserver_port
    to_port     = var.apiserver_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

}

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

  ingress {
    description     = "connection to API server from Loadbalancer"
    from_port       = var.apiserver_port
    to_port         = var.apiserver_port
    protocol        = "tcp"
    security_groups = [aws_security_group.apiserver_lb.id]
  }

  ingress {
    description     = "ssh from jumphost"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jumphost.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = [ingress]
  }
}
